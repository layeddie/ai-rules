# Mnesia Patterns

**Purpose**: Mnesia distributed database patterns for Elixir/BEAM applications.

## Quick Start

```elixir
# Create Mnesia schema
defmodule MyApp.User do
  defstruct [:id, :email, :name, :created_at]
end

# Start Mnesia
:mnesia.start()
:mnesia.create_table(:users, disc_copies: [node()], attributes: [:id, :email, :name, :created_at])
:mnesia.wait_for_tables([:users], 5_000)
```

## Schema Definition

### 1. Record Definition

```elixir
defmodule MyApp.Records do
  require Record

  Record.defrecord :user, id: nil, email: nil, name: nil, created_at: nil
  Record.defrecord :product, id: nil, name: nil, price: nil, stock: nil
  Record.defrecord :order, id: nil, user_id: nil, total: nil, status: nil, created_at: nil
end
```

### 2. Table Creation

```elixir
defmodule MyApp.Mnesia do
  require MyApp.Records
  require Logger

  # Client API
  def start(), do: :mnesia.start()
  def start_cluster(), do: :mnesia.start() && :mnesia.change_config(:extra_db_nodes, Node.list())
  def create_table(table_name, opts), do: :mnesia.create_table(table_name, opts)
  def wait_for_tables(tables, timeout \\ 5_000), do: :mnesia.wait_for_tables(tables, timeout)

  # Create users table
  def create_users_table() do
    :mnesia.create_table(:users, [
      attributes: [:id, :email, :name, :created_at],
      disc_copies: Node.list(),
      type: :set,
      index: [:email]
    ])
  end

  # Create products table
  def create_products_table() do
    :mnesia.create_table(:products, [
      attributes: [:id, :name, :price, :stock],
      disc_copies: Node.list(),
      type: :set,
      index: [:name]
    ])
  end

  # Create orders table
  def create_orders_table() do
    :mnesia.create_table(:orders, [
      attributes: [:id, :user_id, :total, :status, :created_at],
      disc_copies: Node.list(),
      type: :set,
      index: [:user_id, :status]
    ])
  end
end
```

## Query Patterns

### 1. Simple Query

```elixir
# Get user by ID
def get_user(user_id) do
  case :mnesia.read(:users, user_id) do
    [user_record] -> {:ok, MyApp.Records.user(user_record)}
    [] -> {:error, :not_found}
  end
end

# Get user by email
def get_user_by_email(email) do
  case :mnesia.dirty_read(:users, email, :email) do
    [user_record] -> {:ok, MyApp.Records.user(user_record)}
    [] -> {:error, :not_found}
  end
end
```

### 2. Pattern Matching Query

```elixir
# Get all active orders
def get_active_orders() do
  :mnesia.transaction(fn ->
    :mnesia.match_object(:orders, {:_, :_, :_, :active, :_})
  end)
end

# Get orders for specific user
def get_user_orders(user_id) do
  :mnesia.transaction(fn ->
    :mnesia.match_object(:orders, {:_, user_id, :_, :_, :_})
  end)
end
```

### 3. Complex Query with Funnel

```elixir
# Get users created in last 7 days
def get_recent_users(days \\ 7) do
  cutoff_date = DateTime.utc_now() |> DateTime.add(-days * 24 * 60 * 60, :second)

  :mnesia.transaction(fn ->
    :mnesia.foldl(fn
      user_record = {:users, _id, _email, _name, created_at}, acc ->
        if DateTime.compare(created_at, cutoff_date) != :lt do
          [user_record | acc]
        else
          acc
        end
    end, [], :users)
  end)
end
```

### 4. ETS-like Interface

```elixir
defmodule MyApp.MnesiaCache do
  require Logger

  # Client API
  def get(key), do: get_by_id(:cache, key)
  def put(key, value), do: put_by_id(:cache, key, value)
  def delete(key), do: delete_by_id(:cache, key)

  # Implementation
  defp get_by_id(table, key) do
    case :mnesia.read(table, key) do
      [{:cache, _id, value}] -> {:ok, value}
      [] -> {:error, :not_found}
      _ -> {:error, :invalid_record}
    end
  end

  defp put_by_id(table, key, value) do
    :mnesia.transaction(fn ->
      :mnesia.write(table, {table, key, value})
    end)
  end

  defp delete_by_id(table, key) do
    :mnesia.transaction(fn ->
      :mnesia.delete(table, key)
    end)
  end
end
```

## Replication Patterns

### 1. Table Fragmentation

```elixir
# Create fragmented table across nodes
defmodule MyApp.Mnesia do
  def create_fragments_table(table_name, fragment_count) do
    nodes = Node.list()
    
    # Create fragmented table
    :mnesia.create_table(table_name, [
      attributes: [:id, :email, :name, :created_at],
      disc_copies: nodes,
      type: :set,
      index: [:email],
      frag_properties: [{:node_pool, nodes, :n_fragments, fragment_count}]
    ])
  end
end
```

### 2. Event Replication

```elixir
defmodule MyApp.EventReplication do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def subscribe(event_type), do: GenServer.cast(__MODULE__, {:subscribe, event_type})
  def publish(event), do: GenServer.cast(__MODULE__, {:publish, event})

  # Server Callbacks
  @impl true
  def init(opts) do
    Logger.info("Starting event replication")
    {:ok, %{subscribers: %{}, opts: opts}}
  end

  @impl true
  def handle_cast({:subscribe, event_type}, state) do
    Logger.info("Subscribing to event: #{event_type}")
    {:noreply, put_in(state, [:subscribers, event_type], self())}
  end

  @impl true
  def handle_cast({:publish, event = {event_type, _id, _data}}, state) do
    Logger.info("Publishing event: #{event_type}")
    
    # Replicate to all nodes
    Enum.each(Node.list(), fn node ->
      :rpc.cast(node, __MODULE__, :handle_remote_event, [event])
    end)
    
    {:noreply, state}
  end

  @impl true
  def handle_info({:remote_event, event = {event_type, _id, _data}}, state) do
    # Handle event from remote node
    Logger.info("Received remote event: #{event_type}")
    
    # Notify local subscribers
    case get_in(state, [:subscribers, event_type]) do
      nil -> :ok
      subscribers -> Enum.each(subscribers, &send(&1, event))
    end
    
    {:noreply, state}
  end
end
```

## Consistency Patterns

### 1. Read-Write Locks

```elixir
defmodule MyApp.LockService do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def acquire_lock(resource_id, timeout \\ 5_000), do: GenServer.call(__MODULE__, {:acquire_lock, resource_id}, timeout)
  def release_lock(resource_id), do: GenServer.cast(__MODULE__, {:release_lock, resource_id})

  # Server Callbacks
  @impl true
  def init(opts), do: {:ok, %{locks: %{}, opts: opts}}

  @impl true
  def handle_call({:acquire_lock, resource_id}, from, state) do
    case Map.get(state.locks, resource_id) do
      nil ->
        # Lock is available
        new_locks = Map.put(state.locks, resource_id, from)
        {:reply, {:ok, :locked}, %{state | locks: new_locks}}
      _owner ->
        # Lock is held by someone else
        {:reply, {:error, :locked}, state}
    end
  end

  @impl true
  def handle_cast({:release_lock, resource_id}, state) do
    new_locks = Map.delete(state.locks, resource_id)
    {:noreply, %{state | locks: new_locks}}
  end
end
```

### 2. Write-Ahead Logging

```elixir
defmodule MyApp.WriteAheadLog do
  require Logger

  # Client API
  def write_operation(operation, data) do
    :mnesia.transaction(fn ->
      :mnesia.write(:wal, {:wal, :erlang.unique_integer([:operation_id]), operation, data, DateTime.utc_now()})
    end)
  end

  def replay_operations() do
    :mnesia.transaction(fn ->
      :mnesia.foldl(fn
        {:wal, _id, operation, data, timestamp}, acc ->
          case execute_operation(operation, data) do
            :ok -> [operation | acc]
            {:error, reason} ->
              Logger.error("Failed to replay operation: #{operation}, reason: #{inspect(reason)}")
              acc
          end
        end, [], :wal)
    end)
  end

  defp execute_operation(:create_user, data), do: # Create user logic
  defp execute_operation(:update_user, data), do: # Update user logic
  defp execute_operation(:delete_user, data), do: # Delete user logic
end
```

## Migration Patterns

### 1. Schema Migration

```elixir
defmodule MyApp.MnesiaMigration do
  require Logger

  def migrate(from_version, to_version) do
    Logger.info("Migrating Mnesia schema from #{from_version} to #{to_version}")
    
    case to_version do
      1 -> migrate_to_v1()
      2 -> migrate_to_v2()
      _ -> {:error, :unknown_version}
    end
  end

  defp migrate_to_v1() do
    # Add index to users table
    :mnesia.add_table_index(:users, :email)
    Logger.info("Added email index to users table")
  end

  defp migrate_to_v2() do
    # Add new column to users table
    :mnesia.transform_table(:users, false, fn
      {users, id, email, name, created_at} ->
        # Add new column (e.g., status)
        {users, id, email, name, :active, created_at}
    end)
    Logger.info("Added status column to users table")
  end
end
```

## Best Practices

### DO

✅ **Start Mnesia early**: Start before other components
✅ **Use transactions**: Wrap operations in :mnesia.transaction
✅ **Choose table type wisely**: :set, :ordered_set, :bag based on access patterns
✅ **Use indexes**: Index frequently queried fields
✅ **Handle failures**: Design for node failures and network partitions
✅ **Test replication**: Verify data consistency across nodes
✅ **Use disk copies**: Persist data with :disc_copies for durability
✅ **Monitor table size**: Large tables need cleanup and archiving
✅ **Backup regularly**: Export data and restore on failures
✅ **Use fragmentation**: Distribute large tables across nodes

### DON'T

❌ **Forget to wait for tables**: Use :mnesia.wait_for_tables
❌ **Mix table types**: Choose consistent type across tables
❌ **Ignore node topology**: Distribute tables across nodes
❌ **Use dirty reads for consistency**: Only for performance-critical read-heavy workloads
❌ **Forget about fragmentation**: Large tables need fragmentation
❌ **Ignore performance**: Monitor query performance and optimize
❌ **Mix synchronous and asynchronous**: Choose consistent approach
❌ **Forget to backup**: Backup before migrations
❌ **Overuse dirty operations**: Use transactions for consistency

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Use for distributed system design
- **DevOps Engineer**: Use for deployment and configuration
- **Database Architect**: Use for schema design and migration
- **QA**: Test distributed scenarios (network partitions, node failures)
- **Security Architect**: Implement secure inter-node communication

### Skills to Reference

- **distributed-systems**: This skill for comprehensive patterns
- **otp-patterns**: GenServer and Supervisor patterns
- **observability**: Monitor Mnesia health and performance
- **test-generation**: Write tests for distributed scenarios

### Documentation Links

- **Clustering Strategies**: `patterns/clustering_strategies.md` (already created)
- **Distributed Supervision**: `patterns/distributed_supervision.md` (already created)
- **Network Partition Handling**: `skills/distributed-systems/SKILL.md` (already created)

---

## Summary

Mnesia provides:
- ✅ Distributed database with replication
- ✅ Consistency through transactions
- ✅ High availability with node redundancy
- ✅ Query capabilities with indexes
- ✅ Schema migration support
- ✅ Write-ahead logging for durability

**Key**: Start Mnesia early, use transactions, handle failures, monitor performance, and backup regularly.
