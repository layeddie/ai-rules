# Distributed Caching Patterns

## Overview

Patterns for implementing distributed caching across multiple nodes using Redis, Nebulex, or other distributed cache stores.

## Redis with Nebulex

### Basic Redis Cache Setup

```elixir
# config/dev.exs
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Redis,
  backend: :redix,
  url: System.get_env("REDIS_URL", "redis://localhost:6379/0")

# config/test.exs
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Local,
  gc_interval: :timer.hours(1)

defmodule MyApp.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis

  # Cache wrapper for user data
  def get_user(user_id) do
    case get("user:#{user_id}") do
      nil ->
        user = Accounts.get_user!(user_id)
        set("user:#{user_id}", user, ttl: :timer.hours(1))
        user
      user ->
        user
    end
  end

  def invalidate_user(user_id) do
    delete("user:#{user_id}")
  end
end
```

### Redis Connection Pooling

```elixir
# config/prod.exs
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Redis,
  backend: :redix,
  # Connection pool configuration
  pool_size: 10,
  max_overflow: 5,
  url: System.get_env("REDIS_URL"),
  # Connection options
  socket_opts: [
    tcp: [keepalive: true]
  ],
  # Retry configuration
  retry: [
    linear_backoff: 100,
    max_retries: 3
  ]

defmodule MyApp.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis,
    # Custom adapter options
    opts: [
      # Key prefix for namespacing
      key_prefix: "myapp:",
      # Encoding (default is :erlang_term)
      codec: Nebulex.TimeCodec
    ]
end
```

## Cache Distribution Strategies

### 1. Sharded Caching

```elixir
defmodule Cache.Sharded do
  @moduledoc """
  Distributes cache keys across multiple Redis instances.
  Reduces load on single cache server.
  """
  use GenServer

  @shards [
    {:redis1, "redis://redis1.example.com:6379/0"},
    {:redis2, "redis://redis2.example.com:6379/0"},
    {:redis3, "redis://redis3.example.com:6379/0"}
  ]

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key) do
    shard_name = shard_for_key(key)
    GenServer.call(__MODULE__, {:get, shard_name, key})
  end

  def set(key, value, ttl \\ 3600) do
    shard_name = shard_for_key(key)
    GenServer.call(__MODULE__, {:set, shard_name, key, value, ttl})
  end

  defp shard_for_key(key) do
    # Consistent hashing
    hash = :erlang.phash2(key)
    index = rem(hash, length(@shards))
    elem(Enum.at(@shards, index), 0)
  end

  @impl true
  def init(_opts) do
    shards = Enum.map(@shards, fn {name, url} ->
      {:ok, conn} = Redix.start_link(url, name: :"redis_#{name}")
      {name, conn}
    end)

    {:ok, %{shards: Map.new(shards)}}
  end

  @impl true
  def handle_call({:get, shard_name, key}, _from, state) do
    conn = Map.get(state.shards, shard_name)
    case Redix.command(conn, ["GET", key]) do
      {:ok, nil} -> {:reply, nil, state}
      {:ok, value} -> {:reply, :erlang.binary_to_term(value), state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_call({:set, shard_name, key, value, ttl}, _from, state) do
    conn = Map.get(state.shards, shard_name)
    serialized = :erlang.term_to_binary(value)
    result = Redix.command(conn, ["SETEX", key, ttl, serialized])
    {:reply, result, state}
  end
end
```

### 2. Distributed Cache with ETS Replication

```elixir
defmodule Cache.DistributedETS do
  @moduledoc """
  Replicates ETS cache across nodes using Phoenix.PubSub.
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def set(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:set, key, value, ttl})

  @impl true
  def init(_opts) do
    table = :ets.new(:distributed_cache, [:named_table, :public, :set])

    # Subscribe to cache update events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "cache:updates")

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(state.table, key) do
      [{^key, value, expires_at}] ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:reply, value, state}
        else
          :ets.delete(state.table, key)
          {:reply, nil, state}
        end
      [] ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:set, key, value, ttl}, _from, state) do
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    :ets.insert(state.table, {key, value, expires_at})

    # Broadcast update to all nodes
    Phoenix.PubSub.broadcast(MyApp.PubSub, "cache:updates", {:cache_update, key, value, expires_at})

    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:cache_update, key, value, expires_at}, state) do
    :ets.insert(state.table, {key, value, expires_at})
    {:noreply, state}
  end
end
```

## Cache Invalidation Across Nodes

### PubSub-Based Invalidation

```elixir
defmodule Cache.DistributedInvalidation do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def invalidate(key), do: GenServer.cast(__MODULE__, {:invalidate, key})

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "cache:invalidation")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:invalidate, key}, state) do
    MyApp.Cache.delete(key)

    # Broadcast invalidation to all nodes
    Phoenix.PubSub.broadcast(MyApp.PubSub, "cache:invalidation", {:invalidate, key})

    {:noreply, state}
  end

  @impl true
  def handle_info({:invalidate, key}, state) do
    MyApp.Cache.delete(key)
    {:noreply, state}
  end
end
```

### Automatic Invalidation on Data Changes

```elixir
defmodule Cache.AutomaticInvalidation do
  @moduledoc """
  Automatically invalidates cache when underlying data changes.
  Uses Ecto.Multi and event broadcasting.
  """

  def with_cache_invalidation(resource_type, resource_id, fun) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:update, fun)
    |> Repo.transaction()
    |> broadcast_invalidation(resource_type, resource_id)
  end

  defp broadcast_invalidation({:ok, _result}, resource_type, resource_id) do
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "cache:invalidation",
      {:invalidate, "#{resource_type}:#{resource_id}"}
    )
    {:ok, :invalidated}
  end

  defp broadcast_invalidation({:error, _reason} = error, _resource_type, _resource_id), do: error
end

# Usage in context module
defmodule Accounts do
  def update_user(user_id, attrs) do
    Cache.AutomaticInvalidation.with_cache_invalidation(:user, user_id, fn multi ->
      multi
      |> Ecto.Multi.update(:user, User.changeset(user_id, attrs))
    end)
  end
end
```

## Multi-Level Caching (Local + Distributed)

```elixir
defmodule Cache.MultiLevel do
  @moduledoc """
  Two-level caching: Local ETS (L1) + Redis (L2).
  Reduces distributed cache calls for frequently accessed data.
  """
  use GenServer

  @local_ttl :timer.minutes(5)
  @remote_ttl :timer.hours(1)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key) do
    with {:ok, value} <- get_local(key) do
      {:ok, value}
    else
      :not_found ->
        case get_remote(key) do
          {:ok, value} ->
            set_local(key, value, @local_ttl)
            {:ok, value}
          :not_found ->
            :not_found
        end
    end
  end

  def set(key, value, ttl \\ @remote_ttl) do
    :ok = set_local(key, value, min(ttl, @local_ttl))
    :ok = set_remote(key, value, ttl)
    :ok
  end

  defp get_local(key) do
    case Cache.Local.get(key) do
      nil -> :not_found
      value -> {:ok, value}
    end
  end

  defp get_remote(key) do
    case MyApp.Cache.get(key) do
      nil -> :not_found
      value -> {:ok, value}
    end
  end

  defp set_local(key, value, ttl), do: Cache.Local.put(key, value, ttl)
  defp set_remote(key, value, ttl), do: MyApp.Cache.set(key, value, ttl: ttl)
end
```

## Cache Warming

### Distributed Cache Warming

```elixir
defmodule Cache.Warmer do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.hours(1), :warm_cache)
    send(self(), :warm_cache)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:warm_cache, state) do
    warm_popular_data()
    {:noreply, state}
  end

  defp warm_popular_data do
    # Warm frequently accessed data
    warm_users()
    warm_posts()
    warm_settings()
  end

  defp warm_users do
    Accounts.list_popular_users(limit: 100)
    |> Enum.each(fn user ->
      MyApp.Cache.set("user:#{user.id}", user, ttl: :timer.hours(2))
    end)
  end

  defp warm_posts do
    Posts.list_recent(limit: 50)
    |> Enum.each(fn post ->
      MyApp.Cache.set("post:#{post.id}", post, ttl: :timer.minutes(30))
    end)
  end

  defp warm_settings do
    Settings.get_all()
    |> Enum.each(fn setting ->
      MyApp.Cache.set("setting:#{setting.key}", setting.value, ttl: :timer.days(1))
    end)
  end
end
```

## Cache Failover

### Redis Sentinel Integration

```elixir
# config/prod.exs
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Redis,
  backend: :redix,
  # Sentinel configuration
  url: nil,  # No direct URL, use sentinel
  sentinel: [
    sentinels: [
      ["redis-sentinel-1.example.com", 26379],
      ["redis-sentinel-2.example.com", 26379],
      ["redis-sentinel-3.example.com", 26379]
    ],
    group: "mymaster",
    password: System.get_env("REDIS_PASSWORD")
  ]

defmodule MyApp.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end
```

### Circuit Breaker for Cache

```elixir
defmodule Cache.CircuitBreaker do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key, fallback_fn) do
    if circuit_open?() do
      fallback_fn.()
    else
      case MyApp.Cache.get(key) do
        nil ->
          value = fallback_fn.()
          MyApp.Cache.set(key, value, ttl: :timer.hours(1))
          value
        value ->
          value
      end
    end
  rescue
    e ->
      record_failure()
      fallback_fn.()
  end

  @impl true
  def init(_opts) do
    {:ok, %{failures: 0, state: :closed, last_failure: nil}}
  end

  defp circuit_open? do
    state = GenServer.call(__MODULE__, :get_state)
    state == :open
  end

  defp record_failure do
    GenServer.cast(__MODULE__, :record_failure)
  end

  @impl true
  def handle_cast(:record_failure, state) do
    new_state =
      %{failures: state.failures + 1, last_failure: DateTime.utc_now(), state: :state.state}
      |> maybe_open_circuit()

    {:noreply, new_state}
  end

  defp maybe_open_circuit(state) do
    if state.failures > 5 do
      %{state | state: :open}
    else
      state
    end
  end
end
```

## Distributed Cache Monitoring

```elixir
defmodule Cache.Metrics do
  @moduledoc """
  Monitor distributed cache performance and health.
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def record_hit(key), do: GenServer.cast(__MODULE__, {:hit, key})
  def record_miss(key), do: GenServer.cast(__MODULE__, {:miss, key})
  def get_stats, do: GenServer.call(__MODULE__, :get_stats)

  @impl true
  def init(_opts) do
    :telemetry.attach("distributed-cache-metrics", [:distributed_cache, :read], &handle_event/4, nil)
    {:ok, %{hits: %{}, misses: %{}, nodes: %{}}}
  end

  @impl true
  def handle_cast({:hit, key}, state) do
    {:noreply, update_in(state.hits[key], &((&1 || 0) + 1))}
  end

  @impl true
  def handle_cast({:miss, key}, state) do
    {:noreply, update_in(state.misses[key], &((&1 || 0) + 1))}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = Enum.map(state.hits, fn {key, hits} ->
      misses = Map.get(state.misses, key, 0)
      total = hits + misses
      hit_rate = if total > 0, do: hits / total, else: 0
      {key, %{hits: hits, misses: misses, hit_rate: hit_rate}}
    end)

    {:reply, stats, state}
  end

  def handle_event([:distributed_cache, :read], measurements, metadata, _config) do
    if measurements.hit? do
      record_hit(metadata.key)
    else
      record_miss(metadata.key)
    end
  end
end
```

## Related Skills

- [Caching Strategies](../skills/caching-strategies/SKILL.md) - Comprehensive caching patterns
- [Distributed Systems](../skills/distributed-systems/SKILL.md) - Distributed system patterns

## Related Patterns

- [Cache Invalidation](../cache_invalidation.md) - Cache invalidation strategies
- [Clustering Strategies](../clustering_strategies.md) - Multi-node coordination
