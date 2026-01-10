# Database Replication Patterns

## Overview

Patterns for implementing database replication to distribute read/write load and improve availability.

## Read/Write Splitting

### Basic Read/Write Split

```elixir
# Primary database (write)
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_PRIMARY_URL"),
  pool_size: 10

# Replica database (read)
config :my_app, MyApp.ReadReplicaRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_REPLICA_URL"),
  pool_size: 20

# Usage in context
defmodule MyApp.Accounts do
  def list_users do
    # Read from replica
    MyApp.ReadReplicaRepo.all(User)
  end

  def get_user!(id) do
    # Read from replica
    MyApp.ReadReplicaRepo.get!(User, id)
  end

  def create_user(attrs) do
    # Write to primary
    MyApp.Repo.insert(User.changeset(%User{}, attrs))
  end

  def update_user(user, attrs) do
    # Write to primary
    user
    |> User.changeset(attrs)
    |> MyApp.Repo.update()
  end

  def delete_user(user) do
    # Write to primary
    MyApp.Repo.delete(user)
  end
end
```

### Read/Write Selector Module

```elixir
defmodule MyApp.ReadWriteSelector do
  @moduledoc """
  Selects appropriate repository for read/write operations.
  """

  def repo_for_action(:read), do: MyApp.ReadReplicaRepo
  def repo_for_action(:write), do: MyApp.Repo

  def repo_for_action(:read_strong), do: MyApp.Repo  # Strong consistency needed

  def execute(action, queryable) do
    repo = repo_for_action(action)
    repo.all(queryable)
  end

  def execute!(action, queryable, id) do
    repo = repo_for_action(action)
    repo.get!(queryable, id)
  end

  def transaction(action, fun) do
    repo = repo_for_action(action)
    repo.transaction(fun)
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users do
    MyApp.ReadWriteSelector.execute(:read, User)
  end

  def get_user!(id) do
    MyApp.ReadWriteSelector.execute!(:read, User, id)
  end

  def get_user_strong!(id) do
    # Strong consistency - read from primary
    MyApp.ReadWriteSelector.execute!(:read_strong, User, id)
  end

  def create_user(attrs) do
    MyApp.ReadWriteSelector.transaction(:write, fn ->
      MyApp.ReadWriteSelector.execute(:write, User.changeset(%User{}, attrs))
    end)
  end
end
```

## Multiple Replicas

### Replica Selection Strategies

```elixir
defmodule MyApp.ReplicaSelector do
  @moduledoc """
  Selects replica database based on strategy.
  """
  @replicas [
    MyApp.ReadReplicaRepo1,
    MyApp.ReadReplicaRepo2,
    MyApp.ReadReplicaRepo3
  ]

  def select_replica(strategy \\ :round_robin)

  def select_replica(:round_robin) do
    index = :ets.update_counter(:replica_index, :current, 1, {1, 0})
    Enum.at(@replicas, rem(index, length(@replicas)))
  end

  def select_replica(:random) do
    Enum.random(@replicas)
  end

  def select_replica(:least_loaded) do
    @replicas
    |> Enum.map(fn repo ->
      {repo, get_repo_load(repo)}
    end)
    |> Enum.min_by(fn {_repo, load} -> load end)
    |> elem(0)
  end

  def select_replica(:health_check) do
    @replicas
    |> Enum.filter(&healthy_replica?/1)
    |> Enum.random()
  end

  defp get_repo_load(repo) do
    # Get current load from monitoring
    # Could be active connection count, query latency, etc.
    :ets.lookup_element(:repo_load, repo, 2)
  end

  defp healthy_replica?(repo) do
    # Check replica health
    case repo.query("SELECT 1") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users do
    repo = MyApp.ReplicaSelector.select_replica(:least_loaded)
    repo.all(User)
  end

  def get_user!(id) do
    repo = MyApp.ReplicaSelector.select_replica(:health_check)
    repo.get!(User, id)
  end
end
```

### Replica Failover

```elixir
defmodule MyApp.ReplicaFailover do
  use GenServer

  @replicas [
    MyApp.ReadReplicaRepo1,
    MyApp.ReadReplicaRepo2,
    MyApp.ReadReplicaRepo3
  ]

  @check_interval :timer.seconds(30)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_healthy_replica do
    GenServer.call(__MODULE__, :get_healthy_replica)
  end

  def get_all_healthy_replicas do
    GenServer.call(__MODULE__, :get_all_healthy_replicas)
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(@check_interval, :check_replica_health)

    healthy_replicas =
      @replicas
      |> Enum.filter(&check_replica_health/1)

    {:ok, %{healthy_replicas: healthy_replicas}}
  end

  @impl true
  def handle_info(:check_replica_health, state) do
    healthy_replicas =
      @replicas
      |> Enum.filter(&check_replica_health/1)

    {:noreply, %{state | healthy_replicas: healthy_replicas}}
  end

  @impl true
  def handle_call(:get_healthy_replica, _from, state) do
    case state.healthy_replicas do
      [] ->
        # No healthy replicas, fallback to primary
        {:reply, MyApp.Repo, state}

      replicas ->
        {:reply, Enum.random(replicas), state}
    end
  end

  @impl true
  def handle_call(:get_all_healthy_replicas, _from, state) do
    {:reply, state.healthy_replicas, state}
  end

  defp check_replica_health(repo) do
    case repo.query("SELECT 1") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users do
    repo = MyApp.ReplicaFailover.get_healthy_replica()
    repo.all(User)
  end
end
```

## Replication Lag Monitoring

### Tracking Replication Lag

```elixir
defmodule MyApp.ReplicationLag do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_lag, do: GenServer.call(__MODULE__, :get_lag)
  def is_healthy?(threshold \\ 5), do: GenServer.call(__MODULE__, {:is_healthy, threshold})

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.seconds(10), :check_lag)
    {:ok, %{lag: nil, last_check: nil}}
  end

  @impl true
  def handle_info(:check_lag, state) do
    lag = measure_replication_lag()
    {:noreply, %{state | lag: lag, last_check: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:get_lag, _from, state) do
    {:reply, state.lag, state}
  end

  @impl true
  def handle_call({:is_healthy, threshold}, _from, state) do
    case state.lag do
      nil -> {:reply, true, state}  # Unknown, assume healthy
      lag -> {:reply, lag <= threshold, state}
    end
  end

  defp measure_replication_lag do
    # Query replication lag
    # PostgreSQL example:
    query = """
      SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds
    """

    case MyApp.ReadReplicaRepo.query(query) do
      {:ok, %Postgrex.Result{rows: [[lag_seconds]]}} ->
        Float.round(lag_seconds, 2)
      {:error, _} ->
        nil
    end
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users do
    case MyApp.ReplicationLag.is_healthy?(5) do
      true ->
        # Replication lag is acceptable, use replica
        MyApp.ReadReplicaRepo.all(User)

      false ->
        # Replication lag is too high, use primary
        MyApp.Repo.all(User)
    end
  end
end
```

## Transaction Handling with Replication

### Read-After-Write Consistency

```elixir
defmodule MyApp.ReadAfterWrite do
  @moduledoc """
  Ensures read-after-write consistency when using replication.
  """

  def write_then_read(operation, read_operation) do
    # Write to primary
    result = operation.()

    # Wait for replication
    wait_for_replication()

    # Read from primary (strong consistency)
    read_operation.(result)
  end

  def write_then_read_replica(operation, read_operation) do
    # Write to primary
    result = operation.()

    # Wait for replication
    wait_for_replication()

    # Read from replica (eventual consistency)
    read_operation.(result)
  end

  defp wait_for_replication(max_retries \\ 10) do
    wait_for_replication_loop(max_retries)
  end

  defp wait_for_replication_loop(0), do: :timeout
  defp wait_for_replication_loop(retries) do
    case MyApp.ReplicationLag.is_healthy?(1) do
      true ->
        :ok

      false ->
        Process.sleep(100)
        wait_for_replication_loop(retries - 1)
    end
  end
end

# Usage
defmodule MyApp.Accounts do
  def create_user_and_return_profile(attrs) do
    MyApp.ReadAfterWrite.write_then_read(
      fn ->
        create_user(attrs)
      end,
      fn {:ok, user} ->
        # Read from primary for consistency
        get_user_profile!(user.id)
      end
    )
  end

  def create_user_and_list_posts(attrs) do
    MyApp.ReadAfterWrite.write_then_read_replica(
      fn ->
        create_user(attrs)
      end,
      fn {:ok, user} ->
        # Read from replica (eventual consistency is OK)
        list_user_posts(user.id)
      end
    )
  end
end
```

## Backup Replicas

### Hot Standby Setup

```elixir
# config/prod.exs
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_PRIMARY_URL"),
  pool_size: 10

config :my_app, MyApp.StandbyRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_STANDBY_URL"),
  pool_size: 5,
  # Configure as standby
  primary: false

# Usage for failover
defmodule MyApp.Failover do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def promote_standby do
    GenServer.call(__MODULE__, :promote_standby)
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.minutes(1), :check_primary_health)

    {:ok, %{primary_healthy: true, failover_triggered: false}}
  end

  @impl true
  def handle_info(:check_primary_health, state) do
    primary_healthy = check_primary_health()

    if not primary_healthy and not state.failover_triggered do
      # Trigger failover
      promote_standby()

      {:noreply, %{state | primary_healthy: false, failover_triggered: true}}
    else
      {:noreply, %{state | primary_healthy: primary_healthy}}
    end
  end

  @impl true
  def handle_call(:promote_standby, _from, state) do
    # Promote standby to primary
    result = promote_standby_repo()

    # Update application configuration
    update_primary_config()

    {:reply, result, %{state | failover_triggered: true}}
  end

  defp check_primary_health do
    case MyApp.Repo.query("SELECT 1") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp promote_standby_repo do
    # Execute database-specific promotion command
    # PostgreSQL example:
    # pg_ctl promote -D /var/lib/postgresql/data

    # Or use streaming replication promotion
    MyApp.StandbyRepo.query("SELECT pg_promote();")
  end

  defp update_primary_config do
    # Update application to use standby as primary
    new_url = System.get_env("DATABASE_STANDBY_URL")

    Application.put_env(:my_app, MyApp.Repo,
      url: new_url
    )

    # Reconnect with new configuration
    MyApp.Repo.stop()
    Process.sleep(1000)
    MyApp.Repo.start_link()
  end
end
```

## Related Skills

- [Advanced Database](../skills/advanced-database/SKILL.md) - Comprehensive database patterns

## Related Patterns

- [Database Sharding](../database_sharding.md) - Data distribution across shards
- [Circuit Breaker](../circuit_breaker.md) - Database failure handling
