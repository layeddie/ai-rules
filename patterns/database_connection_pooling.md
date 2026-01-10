# Database Connection Pooling Patterns

## Overview

Patterns for managing database connection pools in Elixir applications for optimal performance.

## Connection Pool Configuration

### Basic Pool Setup

```elixir
# config/dev.exs
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10,
  queue_target: 100,  # Queue target (default: 50)
  queue_interval: 1000,  # Wait time before checkout (default: 1000ms)

# config/prod.exs
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  # Pool size based on database capacity
  pool_size: 20,
  # Queue settings for high concurrency
  queue_target: 1000,
  queue_interval: 5000,
  # Prepared statements (default: true)
  prepare: :unnamed,
  # Statement cache size (default: 100)
  statement_cache_size: 100,
  # Query logging
  loggers: [{Ecto.LogEntry, :log, :info}]

# config/test.exs
config :my_app, MyApp.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 50  # Larger pool for parallel tests
```

### Dynamic Pool Sizing

```elixir
defmodule MyApp.PoolSizing do
  @moduledoc """
  Calculates optimal pool size based on database capacity.
  """

  @doc """
  Calculate pool size based on database configuration.

  Formula: (max_connections - reserved_connections) / number_of_app_nodes

  Example: Postgres max_connections = 100, reserved = 20, nodes = 2
  Pool size = (100 - 20) / 2 = 40 per node
  """
  def calculate_pool_size(config \\ []) do
    max_connections = Keyword.get(config, :max_connections, 100)
    reserved_connections = Keyword.get(config, :reserved_connections, 20)
    number_of_nodes = Keyword.get(config, :number_of_nodes, 1)

    pool_size = trunc((max_connections - reserved_connections) / number_of_nodes)

    max(pool_size, 1)  # Ensure at least 1 connection
  end

  def get_database_max_connections do
    # Query database for max_connections
    # PostgreSQL: SELECT setting FROM pg_settings WHERE name = 'max_connections';
    case MyApp.Repo.query("SELECT setting FROM pg_settings WHERE name = 'max_connections'") do
      {:ok, %Postgrex.Result{rows: [[max_connections]]}} ->
        String.to_integer(max_connections)
      {:error, _} ->
        100  # Default
    end
  end
end

# Usage in config/prod.exs
config :my_app, MyApp.Repo,
  pool_size: MyApp.PoolSizing.calculate_pool_size(
    max_connections: 100,
    reserved_connections: 20,
    number_of_nodes: 3
  )
```

## Multiple Repositories

### Separate Pools for Different Workloads

```elixir
# Primary application database
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: 20,
  queue_target: 1000,
  queue_interval: 5000

# High-throughput write pool
config :my_app, MyApp.WriteRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_WRITE_URL"),
  pool_size: 30,  # Larger pool for writes
  queue_target: 2000,
  queue_interval: 5000

# Low-latency read pool
config :my_app, MyApp.ReadRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_READ_URL"),
  pool_size: 10,  # Smaller pool for reads
  queue_target: 500,
  queue_interval: 1000

# Background job database
config :my_app, MyApp.JobRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_JOB_URL"),
  pool_size: 5,  # Small pool for background jobs
  queue_target: 100,
  queue_interval: 2000

# Usage
defmodule MyApp.Accounts do
  def create_user(attrs) do
    # Use write pool
    MyApp.WriteRepo.insert(User.changeset(%User{}, attrs))
  end

  def list_users do
    # Use read pool
    MyApp.ReadRepo.all(User)
  end

  def get_user!(id) do
    # Use read pool
    MyApp.ReadRepo.get!(User, id)
  end
end
```

## Pool Monitoring

### Connection Pool Metrics

```elixir
defmodule MyApp.PoolMetrics do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_pool_stats(repo) do
    GenServer.call(__MODULE__, {:get_pool_stats, repo})
  end

  def get_all_pool_stats do
    GenServer.call(__MODULE__, :get_all_pool_stats)
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.seconds(10), :collect_metrics)

    pool_stats = %{
      MyApp.Repo => %{connections: [], max: 0, min: 0, avg: 0},
      MyApp.WriteRepo => %{connections: [], max: 0, min: 0, avg: 0},
      MyApp.ReadRepo => %{connections: [], max: 0, min: 0, avg: 0}
    }

    {:ok, %{pool_stats: pool_stats}}
  end

  @impl true
  def handle_info(:collect_metrics, state) do
    new_pool_stats = collect_pool_metrics(state.pool_stats)
    {:noreply, %{state | pool_stats: new_pool_stats}}
  end

  @impl true
  def handle_call({:get_pool_stats, repo}, _from, state) do
    {:reply, Map.get(state.pool_stats, repo, %{}), state}
  end

  @impl true
  def handle_call(:get_all_pool_stats, _from, state) do
    {:reply, state.pool_stats, state}
  end

  defp collect_pool_metrics(pool_stats) do
    Enum.map(pool_stats, fn {repo, stats} ->
      current_connections = get_connection_count(repo)
      updated_stats = update_stats(stats, current_connections)
      {repo, updated_stats}
    end)
    |> Map.new()
  end

  defp get_connection_count(repo) do
    # Get current connection count from repo
    # This depends on the Ecto adapter implementation
    case repo.query("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database();") do
      {:ok, %Postgrex.Result{rows: [[count]]}} ->
        count
      {:error, _} ->
        0
    end
  end

  defp update_stats(stats, current_connections) do
    connections = [current_connections | stats.connections]
    |> Enum.take(100)  # Keep last 100 data points

    %{
      connections: connections,
      max: Enum.max([current_connections | stats.max]),
      min: Enum.min([current_connections | stats.min]),
      avg: Enum.sum(connections) / length(connections)
    }
  end
end

# Usage
defmodule MyAppWeb.MetricsLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    :timer.send_interval(:timer.seconds(5), :update_metrics)

    {:ok, assign(socket, :pool_stats, MyApp.PoolMetrics.get_all_pool_stats())}
  end

  def handle_info(:update_metrics, socket) do
    {:noreply, assign(socket, :pool_stats, MyApp.PoolMetrics.get_all_pool_stats())}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Database Pool Metrics</h1>
      <%= for {repo, stats} <- @pool_stats do %>
        <div class="pool-stat">
          <h2><%= inspect(repo) %></h2>
          <p>Connections: <%= stats.avg |> Float.round(1) %></p>
          <p>Max: <%= stats.max %></p>
          <p>Min: <%= stats.min %></p>
        </div>
      <% end %>
    </div>
    """
  end
end
```

## Pool Scaling

### Dynamic Pool Adjustment

```elixir
defmodule MyApp.PoolScaler do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def check_and_adjust_pools do
    GenServer.cast(__MODULE__, :check_and_adjust)
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(:timer.minutes(5), :check_and_adjust)
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:check_and_adjust, state) do
    adjust_pools_based_on_load()
    {:noreply, state}
  end

  defp adjust_pools_based_on_load do
    # Check each repo and adjust pool size
    [MyApp.Repo, MyApp.WriteRepo, MyApp.ReadRepo]
    |> Enum.each(&adjust_pool/1)
  end

  defp adjust_pool(repo) do
    current_stats = MyApp.PoolMetrics.get_pool_stats(repo)
    current_pool_size = get_current_pool_size(repo)
    target_pool_size = calculate_target_pool_size(current_stats)

    if abs(target_pool_size - current_pool_size) > 2 do
      # Adjust pool size
      set_pool_size(repo, target_pool_size)
      IO.puts("Adjusting #{inspect(repo)} pool size from #{current_pool_size} to #{target_pool_size}")
    end
  end

  defp calculate_target_pool_size(stats) do
    # Calculate target based on current usage
    # Add 20% buffer for peak usage
    target = trunc(stats.avg * 1.2)
    max(target, 5)  # Minimum pool size
  end

  defp get_current_pool_size(repo) do
    repo.config() |> Keyword.get(:pool_size, 10)
  end

  defp set_pool_size(repo, new_pool_size) do
    current_config = repo.config()
    new_config = Keyword.put(current_config, :pool_size, new_pool_size)

    # Update configuration
    app = repo.config() |> Keyword.get(:otp_app)
    repo_key = Module.split(repo) |> Enum.join(".") |> String.to_atom()

    Application.put_env(app, repo_key, new_config)

    # Restart repo with new configuration
    repo.stop()
    Process.sleep(1000)
    repo.start_link()
  end
end
```

## Pool Exhaustion Handling

### Circuit Breaker for Pool Exhaustion

```elixir
defmodule MyApp.PoolCircuitBreaker do
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def execute(repo, fun) do
    GenServer.call(__MODULE__, {:execute, repo, fun})
  end

  @impl true
  def init(_opts) do
    circuit_state = %{
      MyApp.Repo => :closed,
      MyApp.WriteRepo => :closed,
      MyApp.ReadRepo => :closed
    }

    {:ok, %{circuit_state: circuit_state}}
  end

  @impl true
  def handle_call({:execute, repo, fun}, _from, state) do
    case Map.get(state.circuit_state, repo) do
      :closed ->
        try do
          result = fun.()
          {:reply, {:ok, result}, state}
        rescue
          e in [DBConnection.ConnectionError, Postgrex.Error] ->
            # Circuit opened due to connection error
            IO.puts("Circuit opened for #{inspect(repo)}")
            {:noreply, update_in(state.circuit_state[repo], fn _ -> :open end)}
            {:reply, {:error, e}, state}
        end

      :open ->
        # Circuit is open, return error immediately
        {:reply, {:error, :circuit_open}, state}
    end
  end

  def handle_info(:close_circuit, state) do
    new_circuit_state =
      Enum.map(state.circuit_state, fn {repo, _state} ->
        {repo, :closed}
      end)
      |> Map.new()

    {:noreply, %{state | circuit_state: new_circuit_state}}
  end
end

# Usage
defmodule MyApp.Accounts do
  def create_user(attrs) do
    MyApp.PoolCircuitBreaker.execute(MyApp.WriteRepo, fn ->
      MyApp.WriteRepo.insert(User.changeset(%User{}, attrs))
    end)
  end

  def list_users do
    MyApp.PoolCircuitBreaker.execute(MyApp.ReadRepo, fn ->
      MyApp.ReadRepo.all(User)
    end)
  end
end
```

## Pool Best Practices

### DO: Calculate Pool Size Based on Database Capacity

```elixir
# Good: Calculate based on database capacity
config :my_app, MyApp.Repo,
  pool_size: MyApp.PoolSizing.calculate_pool_size(
    max_connections: 100,
    reserved_connections: 20,
    number_of_nodes: 3
  )

# Bad: Hard-coded pool size
config :my_app, MyApp.Repo,
  pool_size: 10  # May not be optimal for production
```

### DO: Use Separate Pools for Different Workloads

```elixir
# Good: Separate pools for reads and writes
config :my_app, MyApp.Repo,
  pool_size: 20

config :my_app, MyApp.ReadRepo,
  pool_size: 10

# Bad: Single pool for all workloads
config :my_app, MyApp.Repo,
  pool_size: 30  # Writes and reads compete for connections
```

### DON'T: Ignore Pool Exhaustion

```elixir
# Bad: No handling of pool exhaustion
def list_users do
  MyApp.Repo.all(User)
end

# Good: Circuit breaker for pool exhaustion
def list_users do
  MyApp.PoolCircuitBreaker.execute(MyApp.Repo, fn ->
    MyApp.Repo.all(User)
  end)
end
```

## Related Skills

- [Advanced Database](../skills/advanced-database/SKILL.md) - Comprehensive database patterns

## Related Patterns

- [Database Sharding](../database_sharding.md) - Data distribution across shards
- [Database Replication](../database_replication.md) - Read/write splitting
