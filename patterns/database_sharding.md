# Database Sharding Patterns

## Overview

Patterns for implementing database sharding to distribute data across multiple database instances.

## Horizontal Sharding

### Consistent Hashing

```elixir
defmodule MyApp.Sharding.Hashing do
  @moduledoc """
  Consistent hashing for sharding data across multiple databases.
  """
  @shard_count 10

  def shard_for_key(key) do
    :erlang.phash2(key, @shard_count)
  end

  def shard_for_id(id) when is_integer(id), do: rem(id, @shard_count)
  def shard_for_id(%{id: id}), do: rem(id, @shard_count)

  def get_repo_for_shard(shard_id) do
    Module.concat([MyApp.RepoShard, Integer.to_string(shard_id)])
  end

  def get_repo_for_key(key) do
    shard_id = shard_for_key(key)
    get_repo_for_shard(shard_id)
  end

  def get_repo_for_id(id) do
    shard_id = shard_for_id(id)
    get_repo_for_shard(shard_id)
  end
end

# Usage in context
defmodule MyApp.Accounts do
  def create_user(attrs) do
    changeset = User.changeset(%User{}, attrs)

    case changeset do
      %{valid?: true} ->
        repo = MyApp.Sharding.Hashing.get_repo_for_key(attrs[:email])
        repo.insert(changeset)
      error ->
        error
    end
  end

  def get_user!(id) do
    repo = MyApp.Sharding.Hashing.get_repo_for_id(id)
    repo.get!(User, id)
  end

  def update_user(user, attrs) do
    repo = MyApp.Sharding.Hashing.get_repo_for_id(user.id)
    user
    |> User.changeset(attrs)
    |> repo.update()
  end

  def delete_user(user) do
    repo = MyApp.Sharding.Hashing.get_repo_for_id(user.id)
    repo.delete(user)
  end
end
```

### Range-Based Sharding

```elixir
defmodule MyApp.Sharding.Range do
  @moduledoc """
  Range-based sharding for sequential data.
  Useful for time-series data or auto-incrementing IDs.
  """
  @shard_ranges [
    {0, 1000000, 0},
    {1000000, 2000000, 1},
    {2000000, 3000000, 2},
    {3000000, 4000000, 3},
    {4000000, nil, 4}  # Everything else
  ]

  def shard_for_id(id) do
    Enum.find_value(@shard_ranges, fn {min, max, shard_id} ->
      (max == nil and id >= min) or (id >= min and id < max)
    end)
  end

  def get_repo_for_id(id) do
    shard_id = shard_for_id(id)
    Module.concat([MyApp.RepoShard, Integer.to_string(shard_id)])
  end
end

# Usage for log data
defmodule MyApp.Logs do
  def create_log(attrs) do
    changeset = Log.changeset(%Log{}, attrs)

    case changeset do
      %{valid?: true} ->
        # Auto-increment ID determines shard
        {:ok, log} = Repo.insert(changeset)
        repo = MyApp.Sharding.Range.get_repo_for_id(log.id)

        # Copy to appropriate shard
        repo.insert(log)

      error ->
        error
    end
  end

  def get_logs_in_range(min_id, max_id) do
    # Query all shards in range
    @shard_ranges
    |> Enum.filter(fn {min, max, _shard_id} ->
      ranges_overlap?(min, max, min_id, max_id)
    end)
    |> Enum.flat_map(fn {_min, _max, shard_id} ->
      repo = Module.concat([MyApp.RepoShard, Integer.to_string(shard_id)])
      Log
      |> where([l], l.id >= ^min_id and l.id < ^max_id)
      |> repo.all()
    end)
  end

  defp ranges_overlap?(min1, max1, min2, max2) do
    cond do
      max1 == nil -> true
      max2 == nil -> true
      true -> min1 < max2 and min2 < max1
    end
  end
end
```

### Directory-Based Sharding

```elixir
defmodule MyApp.Sharding.Directory do
  @moduledoc """
  Directory-based sharding using a lookup table.
  Allows flexible shard assignment and rebalancing.
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def assign_shard(entity_type, entity_id, shard_id) do
    GenServer.cast(__MODULE__, {:assign_shard, entity_type, entity_id, shard_id})
  end

  def get_shard_for_entity(entity_type, entity_id) do
    GenServer.call(__MODULE__, {:get_shard, entity_type, entity_id})
  end

  def get_repo_for_entity(entity_type, entity_id) do
    shard_id = get_shard_for_entity(entity_type, entity_id)
    Module.concat([MyApp.RepoShard, Integer.to_string(shard_id)])
  end

  def rebalance_shard(old_shard_id, new_shard_id, count \\ 1000) do
    GenServer.cast(__MODULE__, {:rebalance, old_shard_id, new_shard_id, count})
  end

  @impl true
  def init(_opts) do
    table = :ets.new(:shard_directory, [:named_table, :public, :set])

    # Load shard assignments from database
    load_shard_assignments(table)

    {:ok, %{table: table}}
  end

  @impl true
  def handle_cast({:assign_shard, entity_type, entity_id, shard_id}, state) do
    key = {entity_type, entity_id}
    :ets.insert(state.table, {key, shard_id})

    # Persist to database
    persist_shard_assignment(entity_type, entity_id, shard_id)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:rebalance, old_shard_id, new_shard_id, count}, state) do
    # Find entities in old shard
    entities = find_entities_in_shard(old_shard_id, count)

    # Move entities to new shard
    Enum.each(entities, fn {entity_type, entity_id} ->
      :ets.insert(state.table, {{entity_type, entity_id}, new_shard_id})
      move_entity_to_shard(entity_type, entity_id, old_shard_id, new_shard_id)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:get_shard, entity_type, entity_id}, _from, state) do
    key = {entity_type, entity_id}

    case :ets.lookup(state.table, key) do
      [{^key, shard_id}] ->
        {:reply, shard_id, state}
      [] ->
        # Default shard assignment (e.g., hash-based)
        default_shard = :erlang.phash2({entity_type, entity_id}, 10)
        {:reply, default_shard, state}
    end
  end

  defp load_shard_assignments(table) do
    # Load from database
    # Example: SELECT entity_type, entity_id, shard_id FROM shard_assignments
  end

  defp persist_shard_assignment(entity_type, entity_id, shard_id) do
    # Persist to database
    # Example: INSERT INTO shard_assignments (entity_type, entity_id, shard_id) VALUES (?, ?, ?)
  end

  defp find_entities_in_shard(shard_id, count) do
    # Find entities in shard
    # Example: SELECT entity_type, entity_id FROM shard_assignments WHERE shard_id = ? LIMIT ?
  end

  defp move_entity_to_shard(entity_type, entity_id, old_shard_id, new_shard_id) do
    # Copy entity from old shard to new shard
    # Delete from old shard
  end
end
```

## Cross-Shard Queries

### Aggregation Across Shards

```elixir
defmodule MyApp.Sharding.Queries do
  @moduledoc """
  Query patterns for cross-shard operations.
  """

  def count_all_users do
    # Query all shards and aggregate results
    for shard_id <- 0..9 do
      repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)
      repo.aggregate(User, :count, :id)
    end
    |> Enum.sum()
  end

  def get_user_by_email(email) do
    # Determine shard for email
    shard_id = MyApp.Sharding.Hashing.shard_for_key(email)
    repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)

    User
    |> where([u], u.email == ^email)
    |> repo.one()
  end

  def list_all_users_paginated(page, per_page \\ 20) do
    # Paginate across all shards
    offset = (page - 1) * per_page

    # Query each shard with limits
    users_by_shard =
      for shard_id <- 0..9 do
        repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)

        User
        |> order_by([u], asc: u.id)
        |> limit(^per_page)
        |> offset(^div(offset, 10))
        |> repo.all()
      end

    # Merge and paginate
    users_by_shard
    |> List.flatten()
    |> Enum.sort_by(& &1.id)
    |> Enum.take(per_page)
  end

  def search_users(query, page, per_page \\ 20) do
    # Full-text search across all shards
    users_by_shard =
      for shard_id <- 0..9 do
        repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)

        User
        |> where([u], ilike(u.name, ^"%#{query}%"))
        |> limit(^per_page)
        |> repo.all()
      end

    users_by_shard
    |> List.flatten()
    |> Enum.take(per_page)
  end
end
```

## Shard Rebalancing

### Background Rebalancing Process

```elixir
defmodule MyApp.Sharding.Rebalancer do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def check_shard_imbalance(threshold \\ 0.2) do
    GenServer.call(__MODULE__, {:check_imbalance, threshold})
  end

  def trigger_rebalance(shard_id, target_shard_id, count \\ 1000) do
    GenServer.cast(__MODULE__, {:rebalance, shard_id, target_shard_id, count})
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.hours(1), :check_rebalance)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_rebalance, state) do
    # Check for shard imbalance
    check_and_rebalance_if_needed()
    {:noreply, state}
  end

  @impl true
  def handle_call({:check_imbalance, threshold}, _from, state) do
    # Calculate shard sizes
    shard_sizes = calculate_shard_sizes()

    # Check for imbalance
    max_size = Enum.max(shard_sizes)
    min_size = Enum.min(shard_sizes)
    avg_size = Enum.sum(shard_sizes) / length(shard_sizes)

    imbalance = (max_size - min_size) / avg_size

    if imbalance > threshold do
      # Find imbalanced shards
      over_shards = Enum.filter(shard_sizes, fn {_shard_id, size} -> size > avg_size end)
      under_shards = Enum.filter(shard_sizes, fn {_shard_id, size} -> size < avg_size end)

      {:reply, {:imbalanced, over_shards, under_shards}, state}
    else
      {:reply, :balanced, state}
    end
  end

  @impl true
  def handle_cast({:rebalance, shard_id, target_shard_id, count}, state) do
    # Move entities from shard_id to target_shard_id
    rebalance_shard(shard_id, target_shard_id, count)
    {:noreply, state}
  end

  defp calculate_shard_sizes do
    for shard_id <- 0..9 do
      repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)
      count = repo.aggregate(User, :count, :id)
      {shard_id, count}
    end
  end

  defp check_and_rebalance_if_needed do
    case check_shard_imbalance(0.2) do
      {:imbalanced, over_shards, under_shards} ->
        # Rebalance between shards
        over_shard = Enum.random(over_shards)
        under_shard = Enum.random(under_shards)
        trigger_rebalance(elem(over_shard, 0), elem(under_shard, 0), 1000)

      :balanced ->
        :ok
    end
  end

  defp rebalance_shard(shard_id, target_shard_id, count) do
    # Move entities between shards
    # This involves copying data and updating directory
  end
end
```

## Shard Monitoring

### Shard Health Checks

```elixir
defmodule MyApp.Sharding.Monitor do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def check_shard_health(shard_id) do
    GenServer.call(__MODULE__, {:check_health, shard_id})
  end

  def get_shard_status(shard_id) do
    GenServer.call(__MODULE__, {:get_status, shard_id})
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.minutes(5), :check_all_shards)

    shard_status =
      for shard_id <- 0..9 do
        {shard_id, :unknown}
      end
      |> Map.new()

    {:ok, %{shard_status: shard_status}}
  end

  @impl true
  def handle_info(:check_all_shards, state) do
    # Check health of all shards
    new_status =
      for shard_id <- 0..9 do
        {shard_id, check_shard_health_now(shard_id)}
      end
      |> Map.new()

    {:noreply, %{state | shard_status: new_status}}
  end

  @impl true
  def handle_call({:check_health, shard_id}, _from, state) do
    status = check_shard_health_now(shard_id)
    {:reply, status, state}
  end

  @impl true
  def handle_call({:get_status, shard_id}, _from, state) do
    {:reply, Map.get(state.shard_status, shard_id, :unknown), state}
  end

  defp check_shard_health_now(shard_id) do
    repo = MyApp.Sharding.Hashing.get_repo_for_shard(shard_id)

    try do
      # Simple query to check connectivity
      repo.query("SELECT 1")
      :healthy
    rescue
      _ -> :unhealthy
    end
  end
end
```

## Related Skills

- [Advanced Database](../skills/advanced-database/SKILL.md) - Comprehensive database patterns

## Related Patterns

- [Database Replication](../database_replication.md) - Read/write splitting
- [Database Connection Pooling](../database_connection_pooling.md) - Connection management
