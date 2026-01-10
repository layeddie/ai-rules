# Caching Strategies Skill

## Overview

Comprehensive guide to implementing effective caching strategies in Elixir applications, improving performance and reducing database load.

## When to Use Caching

**Use caching when:**
- Data is read frequently but changes infrequently
- Expensive computations or database queries are repeated
- API calls to external services are slow
- You need to reduce database load and improve response times
- Data can tolerate temporary staleness

**Avoid caching when:**
- Data changes frequently (real-time systems)
- Absolute consistency is required (financial transactions)
- Cache invalidation is complex and error-prone
- Cache hit rate is low (<50%)

## ETS Caching (In-Memory)

### DO: Use ETS for Local Caching

```elixir
defmodule Cache.Local do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def put(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:put, key, value, ttl})

  @impl true
  def init(opts) do
    table = :ets.new(:local_cache, [:named_table, :public, read_concurrency: true])
    {:ok, %{table: table, ttl: Keyword.get(opts, :ttl, 3600)}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(state.table, key) do
      [{^key, value, expires_at}] ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:reply, {:ok, value}, state}
        else
          :ets.delete(state.table, key)
          {:reply, :not_found, state}
        end
      [] ->
        {:reply, :not_found, state}
    end
  end

  @impl true
  def handle_call({:put, key, value, ttl}, _from, state) do
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    :ets.insert(state.table, {key, value, expires_at})
    {:reply, :ok, state}
  end
end
```

### DON'T: Use ETS Without Concurrency Options

```elixir
# DON'T: Create tables without read_concurrency
defmodule Cache.Bad do
  def init do
    # This causes contention
    :ets.new(:bad_cache, [:named_table, :public])
  end
end

# DO: Enable read_concurrency for better performance
defmodule Cache.Good do
  def init do
    :ets.new(:good_cache, [:named_table, :public, read_concurrency: true])
  end
end
```

## Distributed Caching (Redis/Nebulex)

### DO: Use Nebulex for Distributed Caching

```elixir
# config.exs
config :my_app, MyApp.Cache,
  adapter: Nebulex.Adapters.Redis,
  backend: :redix,
  url: System.get_env("REDIS_URL")

defmodule MyApp.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis

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
end
```

### DON'T: Cache Entire Database Tables

```elixir
# DON'T: Cache entire tables
defmodule Cache.Bad do
  def all_users do
    get("all_users") || Cache.put("all_users", Accounts.list_users())
  end
end

# DO: Cache specific queries with granular keys
defmodule Cache.Good do
  def active_users(page \\ 1) do
    key = "users:active:page:#{page}"
    case get(key) do
      nil ->
        users = Accounts.list_users(active: true, page: page)
        set(key, users, ttl: :timer.minutes(5))
        users
      users ->
        users
    end
  end
end
```

## Cache Invalidation Strategies

### 1. Time-Based Expiration (TTL)

```elixir
defmodule Cache.TTL do
  @default_ttl 3600  # 1 hour

  def get_with_fallback(key, fallback_fn, ttl \\ @default_ttl) do
    case MyApp.Cache.get(key) do
      nil ->
        value = fallback_fn.()
        MyApp.Cache.set(key, value, ttl: ttl)
        value
      value ->
        value
    end
  end
end

# Usage
Cache.TTL.get_with_fallback(
  "user:#{user_id}",
  fn -> Accounts.get_user!(user_id) end,
  :timer.hours(2)
)
```

### 2. Write-Through Caching

```elixir
defmodule Cache.WriteThrough do
  def update_user(user_id, attrs) do
    with {:ok, user} <- Accounts.update_user(user_id, attrs) do
      # Cache is updated synchronously with database
      MyApp.Cache.set("user:#{user_id}", user, ttl: :timer.hours(1))
      {:ok, user}
    end
  end
end
```

### 3. Cache-Aside (Lazy Loading)

```elixir
defmodule Cache.CacheAside do
  def get_user(user_id) do
    case MyApp.Cache.get("user:#{user_id}") do
      nil ->
        user = Accounts.get_user!(user_id)
        MyApp.Cache.set("user:#{user_id}", user, ttl: :timer.hours(1))
        user
      user ->
        user
    end
  end
end
```

### 4. Event-Based Invalidation

```elixir
defmodule Cache.Invalidation do
  use GenServer

  def subscribe_to(topic), do: Phoenix.PubSub.subscribe(MyApp.PubSub, topic)

  @impl true
  def init(_opts) do
    subscribe_to("user:updated")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:user_updated, user_id}, state) do
    MyApp.Cache.delete("user:#{user_id}")
    MyApp.Cache.delete("user:#{user_id}:profile")
    {:noreply, state}
  end
end

# Invalidate cache on update
defmodule Accounts.User do
  def update_user(user, attrs) do
    with {:ok, user} <- Repo.update(user_changeset(user, attrs)) do
      Phoenix.PubSub.broadcast(MyApp.PubSub, "user:updated", {:user_updated, user.id})
      {:ok, user}
    end
  end
end
```

## Multi-Level Caching

### DO: Combine ETS and Redis for Performance

```elixir
defmodule Cache.MultiLevel do
  @local_ttl :timer.minutes(5)
  @remote_ttl :timer.hours(1)

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

  defp get_local(key), do: Cache.Local.get(key)
  defp get_remote(key), do: MyApp.Cache.get(key)
  defp set_local(key, value, ttl), do: Cache.Local.put(key, value, ttl)
end
```

## Cache Warming

### DO: Warm Cache on Application Startup

```elixir
defmodule MyApp.Application do
  def start(_type, _args) do
    children = [
      {Cache.Local, []},
      {MyApp.Cache, []},
      {Cache.Warmer, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Cache.Warmer do
  use GenServer

  @impl true
  def init(_opts) do
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
    Accounts.list_popular_users()
    |> Enum.each(fn user ->
      Cache.Local.put("user:#{user.id}", user, :timer.hours(1))
    end)
  end
end
```

## Cache Key Design

### DO: Use Descriptive Cache Keys

```elixir
defmodule Cache.Keys do
  def user(user_id), do: "user:#{user_id}"
  def user_profile(user_id), do: "user:#{user_id}:profile"
  def users_list(page, filters), do: "users:page:#{page}:#{hash(filters)}"
  def search_results(query, page), do: "search:#{hash(query)}:page:#{page}"

  defp hash(term), do: :crypto.hash(:md5, to_string(term)) |> Base.encode16()
end
```

### DON'T: Use Ambiguous Cache Keys

```elixir
# DON'T: Non-descriptive keys
Cache.put("u1", user_data)
Cache.put("results", search_results)

# DO: Clear, hierarchical keys
Cache.put("user:123", user_data)
Cache.put("search:elixir:page:1", search_results)
```

## Cache Monitoring

### DO: Monitor Cache Hit Rate

```elixir
defmodule Cache.Metrics do
  use GenServer

  def record_hit(key), do: GenServer.cast(__MODULE__, {:hit, key})
  def record_miss(key), do: GenServer.cast(__MODULE__, {:miss, key})
  def get_stats, do: GenServer.call(__MODULE__, :get_stats)

  @impl true
  def init(_opts) do
    :telemetry.attach("cache-metrics", [:cache, :read], &handle_event/4, nil)
    {:ok, %{hits: %{}, misses: %{}}}
  end

  @impl true
  def handle_cast({:hit, key}, state) do
    {:noreply, update_in(state.hits[key], &(&1 || 0) + 1)}
  end

  @impl true
  def handle_cast({:miss, key}, state) do
    {:noreply, update_in(state.misses[key], &(&1 || 0) + 1)}
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

  def handle_event([:cache, :read], measurements, metadata, _config) do
    case measurements do
      %{hit?: true} -> record_hit(metadata.key)
      %{hit?: false} -> record_miss(metadata.key)
    end
  end
end
```

## Common Pitfalls

### DON'T: Cache Without Invalidation Strategy

```elixir
# DON'T: Cache without invalidation plan
defmodule BadCache do
  def get_user(user_id) do
    get("user:#{user_id}") || put("user:#{user_id}", Accounts.get_user!(user_id))
  end
  # Never invalidates!
end

# DO: Include cache invalidation
defmodule GoodCache do
  def get_user(user_id), do: Cache.CacheAside.get_user(user_id)

  def update_user(user_id, attrs) do
    with {:ok, user} <- Accounts.update_user(user_id, attrs) do
      # Invalidate cache after update
      MyApp.Cache.delete("user:#{user_id}")
      {:ok, user}
    end
  end
end
```

## Related Skills

- [Performance Profiling](../performance-profiling/SKILL.md) - Identify caching opportunities
- [Distributed Systems](../distributed-systems/SKILL.md) - Distributed caching patterns
- [Resilience Patterns](../resilience-patterns/SKILL.md) - Circuit breakers for cache failures

## Related Patterns

- [ETS Performance](../ets_performance.md) - ETS-specific optimization techniques
- [Distributed Supervision](../distributed_supervision.md) - Managing cache processes
