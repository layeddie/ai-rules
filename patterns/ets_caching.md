# ETS Caching Patterns

## Overview

Patterns for efficient in-memory caching using Erlang Term Storage (ETS).

## Basic ETS Cache

### Simple ETS Cache

```elixir
defmodule Cache.ETS do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key), do: :ets.lookup(:cache, key) |> extract_value()
  def set(key, value), do: :ets.insert(:cache, {key, value})
  def delete(key), do: :ets.delete(:cache, key)

  @impl true
  def init(_opts) do
    :ets.new(:cache, [:named_table, :public, :set])
    {:ok, %{}}
  end

  defp extract_value([]), do: nil
  defp extract_value([{_key, value}]), do: value
end
```

### ETS Cache with TTL

```elixir
defmodule Cache.ETSTTL do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def set(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:set, key, value, ttl})
  def delete(key), do: :ets.delete(:cache_ttl, key)

  @impl true
  def init(opts) do
    table = :ets.new(:cache_ttl, [:named_table, :public, :set])
    cleanup_interval = Keyword.get(opts, :cleanup_interval, :timer.minutes(5))
    :timer.send_interval(cleanup_interval, :cleanup)
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
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired(state.table)
    {:noreply, state}
  end

  defp cleanup_expired(table) do
    now = DateTime.utc_now()
    :ets.tab2list(table)
    |> Enum.filter(fn {_key, _value, expires_at} ->
      DateTime.compare(expires_at, now) != :lt
    end)
    |> Enum.each(fn {key, _value, _expires_at} ->
      :ets.delete(table, key)
    end)
  end
end
```

## Read-Optimized ETS Cache

### Concurrency for Reads

```elixir
defmodule Cache.ConcurrentReads do
  use GenServer

  @doc """
  Create table with read_concurrency for high read throughput.
  Multiple readers can access data simultaneously.
  """
  @impl true
  def init(_opts) do
    # read_concurrency: true enables concurrent reads
    table = :ets.new(:concurrent_cache, [
      :named_table,
      :public,
      :set,
      read_concurrency: true
    ])

    {:ok, %{table: table}}
  end

  def get(key), do: :ets.lookup(:concurrent_cache, key) |> extract_value()
  def set(key, value), do: GenServer.call(__MODULE__, {:set, key, value})

  @impl true
  def handle_call({:set, key, value}, _from, state) do
    :ets.insert(state.table, {key, value})
    {:reply, :ok, state}
  end

  defp extract_value([]), do: nil
  defp extract_value([{_key, value}]), do: value
end
```

### Write-Optimized ETS Cache

```elixir
defmodule Cache.ConcurrentWrites do
  @doc """
  Use GenServer for writes, direct ETS for reads.
  Writes go through GenServer (serialized), reads bypass GenServer.
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key), do: :ets.lookup(:write_cache, key) |> extract_value()
  def set(key, value), do: GenServer.call(__MODULE__, {:set, key, value})

  @impl true
  def init(_opts) do
    table = :ets.new(:write_cache, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:set, key, value}, _from, state) do
    # Write is serialized by GenServer
    :ets.insert(state.table, {key, value})
    {:reply, :ok, state}
  end

  defp extract_value([]), do: nil
  defp extract_value([{_key, value}]), do: value
end
```

## ETS Cache with Metrics

### Cache Hit/Miss Tracking

```elixir
defmodule Cache.Metrics do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def set(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:set, key, value, ttl})
  def get_metrics, do: GenServer.call(__MODULE__, :get_metrics)

  @impl true
  def init(_opts) do
    table = :ets.new(:metrics_cache, [:named_table, :public, :set])
    {:ok, %{table: table, hits: 0, misses: 0}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(state.table, key) do
      [{^key, value, expires_at}] ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:reply, value, %{state | hits: state.hits + 1}}
        else
          :ets.delete(state.table, key)
          {:reply, nil, %{state | misses: state.misses + 1}}
        end
      [] ->
        {:reply, nil, %{state | misses: state.misses + 1}}
    end
  end

  @impl true
  def handle_call({:set, key, value, ttl}, _from, state) do
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    :ets.insert(state.table, {key, value, expires_at})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    total = state.hits + state.misses
    hit_rate = if total > 0, do: state.hits / total, else: 0

    metrics = %{
      hits: state.hits,
      misses: state.misses,
      total: total,
      hit_rate: hit_rate
    }

    {:reply, metrics, state}
  end
end
```

## ETS Cache with Bulk Operations

### Bulk Get/Set

```elixir
defmodule Cache.Bulk do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(keys) when is_list(keys), do: GenServer.call(__MODULE__, {:get_bulk, keys})
  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def set(items) when is_list(items), do: GenServer.call(__MODULE__, {:set_bulk, items})
  def set(key, value), do: GenServer.call(__MODULE__, {:set, key, value})

  @impl true
  def init(_opts) do
    table = :ets.new(:bulk_cache, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = :ets.lookup(state.table, key) |> extract_value()
    {:reply, value, state}
  end

  @impl true
  def handle_call({:get_bulk, keys}, _from, state) do
    values = Enum.reduce(keys, %{}, fn key, acc ->
      case :ets.lookup(state.table, key) do
        [{^key, value}] -> Map.put(acc, key, value)
        [] -> acc
      end
    end)

    {:reply, values, state}
  end

  @impl true
  def handle_call({:set, key, value}, _from, state) do
    :ets.insert(state.table, {key, value})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:set_bulk, items}, _from, state) do
    Enum.each(items, fn {key, value} ->
      :ets.insert(state.table, {key, value})
    end)

    {:reply, :ok, state}
  end

  defp extract_value([]), do: nil
  defp extract_value([{_key, value}]), do: value
end
```

## ETS Cache with Pattern Matching

### Pattern-Based Cache Lookup

```elixir
defmodule Cache.PatternMatch do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def find_by_pattern(pattern), do: :ets.match(:pattern_cache, pattern)
  def find(prefix), do: :ets.match(:pattern_cache, {:"$1", :"$2", :"$3"})

  @impl true
  def init(_opts) do
    table = :ets.new(:pattern_cache, [:named_table, :public, :bag, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = :ets.lookup(state.table, key) |> extract_values()
    {:reply, value, state}
  end

  defp extract_values([]), do: []
  defp extract_values(list), do: Enum.map(list, fn {_key, value} -> value end)
end

# Usage example
defmodule Posts do
  def get_post(post_id), do: Cache.PatternMatch.get(post_id)

  def get_posts_by_user(user_id) do
    # Pattern match to find all posts by user
    :ets.match(:pattern_cache, {{:"$1", :"$2", :"$3"}, :_, :"$4"})
    |> Enum.filter(fn [_user, _post_id, _user_id] -> _user_id == user_id end)
    |> Enum.map(fn [user, post_id, _] -> {user, post_id} end)
  end
end
```

## ETS Cache with Size Limits

### LRU Eviction Policy

```elixir
defmodule Cache.LRU do
  use GenServer

  @max_size 1000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def set(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:set, key, value, ttl})

  @impl true
  def init(opts) do
    table = :ets.new(:lru_cache, [:named_table, :public, :set, read_concurrency: true])
    max_size = Keyword.get(opts, :max_size, @max_size)
    {:ok, %{table: table, access_order: [], max_size: max_size}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(state.table, key) do
      [{^key, value, _expires_at}] ->
        # Update access order for LRU
        new_order = [key | state.access_order -- [key]]
        {:reply, value, %{state | access_order: new_order}}
      [] ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:set, key, value, ttl}, _from, state) do
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    :ets.insert(state.table, {key, value, expires_at})

    # Update access order and enforce size limit
    new_order = [key | state.access_order -- [key]]
    new_state = enforce_size_limit(%{state | access_order: new_order})

    {:reply, :ok, new_state}
  end

  defp enforce_size_limit(state) when length(state.access_order) > state.max_size do
    # Evict least recently used items
    keys_to_evict = Enum.drop(state.access_order, state.max_size)
    Enum.each(keys_to_evict, fn key -> :ets.delete(state.table, key) end)

    %{state | access_order: Enum.take(state.access_order, state.max_size)}
  end

  defp enforce_size_limit(state), do: state
end
```

## ETS Cache with Persistence

### Periodic Persistence to Disk

```elixir
defmodule Cache.Persistent do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(key), do: :ets.lookup(:persistent_cache, key) |> extract_value()
  def set(key, value, ttl \\ 3600), do: GenServer.call(__MODULE__, {:set, key, value, ttl})

  @impl true
  def init(opts) do
    table = :ets.new(:persistent_cache, [:named_table, :public, :set, read_concurrency: true])

    # Load persisted data
    load_from_disk()

    # Periodically persist to disk
    persistence_interval = Keyword.get(opts, :persistence_interval, :timer.minutes(5))
    :timer.send_interval(persistence_interval, :persist_to_disk)

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:set, key, value, ttl}, _from, state) do
    expires_at = DateTime.add(DateTime.utc_now(), ttl, :second)
    :ets.insert(state.table, {key, value, expires_at})
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:persist_to_disk, state) do
    persist_to_disk()
    {:noreply, state}
  end

  defp persist_to_disk do
    data = :ets.tab2list(:persistent_cache)
    file_path = Application.get_env(:my_app, :cache_file, "/tmp/cache.ets")
    :ets.tab2file(:persistent_cache, file_path)
  end

  defp load_from_disk do
    file_path = Application.get_env(:my_app, :cache_file, "/tmp/cache.ets")

    if File.exists?(file_path) do
      case :ets.file2tab(file_path) do
        {:ok, table} ->
          # Merge loaded data into existing table
          :ets.tab2list(table)
          |> Enum.each(fn {key, value, expires_at} ->
            :ets.insert(:persistent_cache, {key, value, expires_at})
          end)

          :ets.delete(table)

        {:error, _reason} ->
          # File doesn't exist or is corrupted, start fresh
          :ok
      end
    end
  end

  defp extract_value([]), do: nil
  defp extract_value([{_key, value, _expires_at}]), do: value
end
```

## ETS Performance Tips

### DO: Enable Read Concurrency

```elixir
# Good: Enable read_concurrency for read-heavy workloads
:ets.new(:cache, [:named_table, :public, read_concurrency: true])

# Bad: No read_concurrency, causes contention
:ets.new(:cache, [:named_table, :public])
```

### DO: Use Appropriate Table Type

```elixir
# Use :set for unique keys (most common)
:ets.new(:cache, [:named_table, :public, :set])

# Use :bag for multiple values per key
:ets.new(:tags, [:named_table, :public, :bag])

# Use :ordered_set for ordered iteration
:ets.new(:timeline, [:named_table, :public, :ordered_set])
```

### DON'T: Block GenServer Callbacks with Heavy ETS Operations

```elixir
# Bad: ETS operation in GenServer callback (blocks other requests)
def handle_info(:cleanup, state) do
  # This blocks the GenServer while cleaning up
  cleanup_expired(state.table)
  {:noreply, state}
end

# Good: Use Task for heavy ETS operations
def handle_info(:cleanup, state) do
  Task.start(fn ->
    cleanup_expired(state.table)
  end)
  {:noreply, state}
end
```

## Related Skills

- [Caching Strategies](../skills/caching-strategies/SKILL.md) - Comprehensive caching guide
- [ETS Performance](../ets_performance.md) - ETS-specific optimization techniques

## Related Patterns

- [Cache Invalidation](../cache_invalidation.md) - Cache invalidation strategies
- [Distributed Caching](../distributed_caching.md) - Redis/Nebulex patterns
