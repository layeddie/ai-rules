# Cache Invalidation Patterns

## Overview

Strategies for invalidating cached data when underlying data changes.

## Write-Through Caching

```elixir
defmodule Cache.WriteThrough do
  @doc """
  Update both cache and database synchronously.
  Ensures cache and database are always consistent.
  """
  def update_user(user_id, attrs) do
    with {:ok, user} <- Accounts.update_user(user_id, attrs) do
      # Cache is updated atomically with database
      Cache.set("user:#{user_id}", user, ttl: :timer.hours(1))
      {:ok, user}
    end
  end

  def create_user(attrs) do
    with {:ok, user} <- Accounts.create_user(attrs) do
      Cache.set("user:#{user.id}", user, ttl: :timer.hours(1))
      {:ok, user}
    end
  end
end
```

## Write-Back (Write-Behind) Caching

```elixir
defmodule Cache.WriteBack do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def queue_update(resource, id, attrs) do
    GenServer.cast(__MODULE__, {:queue_update, resource, id, attrs})
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.seconds(30), :flush_queue)
    {:ok, %{queue: :queue.new()}}
  end

  @impl true
  def handle_cast({:queue_update, resource, id, attrs}, state) do
    item = {resource, id, attrs}
    {:noreply, %{state | queue: :queue.in(item, state.queue)}}
  end

  @impl true
  def handle_info(:flush_queue, state) do
    {:value, item, queue} = :queue.out(state.queue)
    flush_item(item)
    {:noreply, %{state | queue: queue}}
  end

  defp flush_item({resource, id, attrs}) do
    apply(Accounts, String.to_existing_atom("update_#{resource}"), [id, attrs])
    Cache.delete("#{resource}:#{id}")
  end
end
```

## Cache-Aside (Lazy Loading) with Invalidation

```elixir
defmodule Cache.CacheAside do
  @moduledoc """
  Cache is loaded on demand (lazy) and invalidated on updates.
  Most common pattern for web applications.
  """

  def get_user(user_id) do
    case Cache.get("user:#{user_id}") do
      nil ->
        user = Accounts.get_user!(user_id)
        Cache.set("user:#{user_id}", user, ttl: :timer.hours(1))
        user
      user ->
        user
    end
  end

  def invalidate_user(user_id) do
    Cache.delete("user:#{user_id}")
  end
end

# Invalidation hooks in context module
defmodule Accounts do
  def update_user(user_id, attrs) do
    with {:ok, user} <- Repo.update(changeset(user, attrs)) do
      # Invalidate cache after successful update
      Cache.CacheAside.invalidate_user(user_id)
      {:ok, user}
    end
  end
end
```

## Time-Based Expiration

```elixir
defmodule Cache.TimeBased do
  @default_ttl 3600  # 1 hour

  def get_with_ttl(key, fallback_fn, ttl \\ @default_ttl) do
    case Cache.get(key) do
      nil ->
        value = fallback_fn.()
        Cache.set(key, value, ttl: ttl)
        value
      value ->
        value
    end
  end

  # Example: Cache recent data for shorter time
  def recent_posts do
    Cache.TimeBased.get_with_ttl(
      "posts:recent",
      fn -> Posts.list_recent(limit: 10) end,
      :timer.minutes(5)  # 5 minutes
    )
  end

  # Example: Cache static data for longer time
  def app_settings do
    Cache.TimeBased.get_with_ttl(
      "settings:app",
      fn -> Settings.get_app_settings() end,
      :timer.hours(24)  # 24 hours
    )
  end
end
```

## Event-Driven Invalidation

### PubSub-Based Invalidation

```elixir
defmodule Cache.Invalidation do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def subscribe(resource_type), do: Phoenix.PubSub.subscribe(MyApp.PubSub, "cache:#{resource_type}")

  @impl true
  def init(_opts) do
    # Subscribe to resource update events
    Phoenix.PubSub.subscribe(MyApp.PubSub, "cache:user")
    Phoenix.PubSub.subscribe(MyApp.PubSub, "cache:post")

    {:ok, %{}}
  end

  @impl true
  def handle_info({:cache_invalidated, resource_type, resource_id}, state) do
    # Invalidate all cache keys for this resource
    Cache.delete("#{resource_type}:#{resource_id}")
    Cache.delete("#{resource_type}:#{resource_id}:profile")
    {:noreply, state}
  end
end

# Broadcast invalidation events on updates
defmodule Accounts do
  def update_user(user_id, attrs) do
    with {:ok, user} <- Repo.update(changeset(user, attrs)) do
      # Broadcast cache invalidation
      Phoenix.PubSub.broadcast(MyApp.PubSub, "cache:user", {:cache_invalidated, :user, user_id})
      {:ok, user}
    end
  end
end
```

### ETS-Based Invalidation

```elixir
defmodule Cache.ETSTracker do
  @doc """
  Track cache dependencies in ETS for bulk invalidation.
  """
  def init do
    :ets.new(:cache_deps, [:named_table, :public, :set])
    :ok
  end

  def track_dependency(parent_key, dependent_key) do
    case :ets.lookup(:cache_deps, parent_key) do
      [{^parent_key, dependencies}] ->
        :ets.insert(:cache_deps, {parent_key, [dependent_key | dependencies]})
      [] ->
        :ets.insert(:cache_deps, {parent_key, [dependent_key]})
    end
  end

  def invalidate_all(parent_key) do
    case :ets.lookup(:cache_deps, parent_key) do
      [{^parent_key, dependencies}] ->
        Enum.each(dependencies, &Cache.delete/1)
        :ets.delete(:cache_deps, parent_key)
      [] ->
        :ok
    end
  end
end

# Usage example
defmodule Posts do
  def create_post(user_id, attrs) do
    with {:ok, post} <- Repo.insert(changeset(attrs)) do
      # Track dependency: user posts depend on user cache
      Cache.ETSTracker.track_dependency("user:#{user_id}", "user:#{user_id}:posts")
      {:ok, post}
    end
  end

  def update_user(user_id, attrs) do
    with {:ok, user} <- Repo.update(changeset(user, attrs)) do
      # Invalidate user and all dependent caches
      Cache.delete("user:#{user_id}")
      Cache.ETSTracker.invalidate_all("user:#{user_id}")
      {:ok, user}
    end
  end
end
```

## Tag-Based Invalidation

```elixir
defmodule Cache.Tags do
  @moduledoc """
  Tag cache entries for bulk invalidation.
  Useful for cache entries that share common invalidation criteria.
  """

  def tag(key, tags) when is_list(tags) do
    Enum.each(tags, &tag(key, &1))
  end

  def tag(key, tag) do
    # Store tag association
    case :ets.lookup(:cache_tags, tag) do
      [{^tag, keys}] ->
        :ets.insert(:cache_tags, {tag, [key | keys]})
      [] ->
        :ets.insert(:cache_tags, {tag, [key]})
    end
  end

  def invalidate_tag(tag) do
    case :ets.lookup(:cache_tags, tag) do
      [{^tag, keys}] ->
        Enum.each(keys, &Cache.delete/1)
        :ets.delete(:cache_tags, tag)
      [] ->
        :ok
    end
  end
end

# Usage example
defmodule Posts do
  def get_post(post_id) do
    key = "post:#{post_id}"
    Cache.Tags.tag(key, [:post, "post:#{post_id}"])
    Cache.get_with_fallback(key, fn -> get_post_from_db(post_id) end)
  end

  def invalidate_post(post_id) do
    Cache.Tags.invalidate_tag("post:#{post_id}")
  end
end
```

## Multi-Key Invalidation

```elixir
defmodule Cache.MultiKey do
  @doc """
  Invalidate multiple related cache keys atomically.
  """
  def invalidate_user_caches(user_id) do
    keys = [
      "user:#{user_id}",
      "user:#{user_id}:profile",
      "user:#{user_id}:settings",
      "user:#{user_id}:posts"
    ]

    Enum.each(keys, &Cache.delete/1)
  end

  def invalidate_search_caches(query) do
    # Invalidate all pages for a search query
    pattern = "search:#{query}:page:*"

    # Use pattern matching for invalidation
    :ets.tab2list(:cache)
    |> Enum.filter(fn {key, _} -> String.starts_with?(key, pattern) end)
    |> Enum.each(fn {key, _} -> Cache.delete(key) end)
  end
end
```

## Cache Stampede Prevention

```elixir
defmodule Cache.StampedePrevention do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_with_lock(key, fallback_fn, ttl \\ 3600) do
    case Cache.get(key) do
      nil ->
        if GenServer.call(__MODULE__, {:try_lock, key}) do
          try do
            value = fallback_fn.()
            Cache.set(key, value, ttl: ttl)
            value
          after
            GenServer.cast(__MODULE__, {:release_lock, key})
          end
        else
          # Wait for cache to be populated by another process
          Process.sleep(100)
          get_with_lock(key, fallback_fn, ttl)
        end
      value ->
        value
    end
  end

  @impl true
  def init(_opts) do
    {:ok, %{locks: %{}}}
  end

  @impl true
  def handle_call({:try_lock, key}, _from, state) do
    case Map.get(state.locks, key) do
      nil ->
        {:reply, true, %{state | locks: Map.put(state.locks, key, true)}}
      _ ->
        {:reply, false, state}
    end
  end

  @impl true
  def handle_cast({:release_lock, key}, state) do
    {:noreply, %{state | locks: Map.delete(state.locks, key)}}
  end
end
```

## Cache Invalidation Best Practices

### DO: Invalidate Consistently

```elixir
# Good: Centralized cache invalidation
defmodule Cache.Invalidator do
  def invalidate_user(user_id) do
    # All user-related cache keys
    [
      "user:#{user_id}",
      "user:#{user_id}:profile",
      "user:#{user_id}:posts",
      "user:#{user_id}:friends"
    ]
    |> Enum.each(&Cache.delete/1)
  end
end

# Bad: Scattered cache invalidation
defmodule BadInvalidation do
  def update_user(user_id, attrs) do
    Repo.update(changeset(user, attrs))
    Cache.delete("user:#{user_id}")  # Forgetting to delete related keys
  end
end
```

### DON'T: Cache Without Expiration

```elixir
# Bad: Cache without expiration
Cache.put("user:#{user_id}", user)

# Good: Always set TTL
Cache.put("user:#{user_id}", user, ttl: :timer.hours(1))
```

## Related Skills

- [Caching Strategies](../skills/caching-strategies/SKILL.md) - Comprehensive caching guide
- [Distributed Systems](../skills/distributed-systems/SKILL.md) - Distributed cache coordination

## Related Patterns

- [ETS Performance](../ets_performance.md) - ETS-based caching patterns
- [Distributed Caching](../distributed_caching.md) - Redis/Nebulex patterns
