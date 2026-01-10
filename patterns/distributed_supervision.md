# Distributed Supervision

**Purpose**: Cross-node supervision patterns for distributed Elixir/BEAM applications.

## Quick Start

```elixir
# DynamicSupervisor across nodes
defmodule MyApp.WorkersSupervisor do
  use DynamicSupervisor

  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)
end
```

## Cross-Node Supervision Patterns

### 1. Local Supervision, Remote Workers

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Local supervisors only
      MyApp.DatabaseSupervisor,
      MyApp.Registry,
      MyApp.LocalSupervisor
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.LocalSupervisor do
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      # Start supervisor for distributed workers
      MyApp.DistributedWorkersSupervisor
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### 2. Distributed DynamicSupervisor with Global Registry

```elixir
defmodule MyApp.DistributedWorkersSupervisor do
  use DynamicSupervisor
  require Logger

  # Client API
  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  def start_worker(worker_module, worker_id, opts \\ []), do
    spec = {worker_module, Keyword.put(opts, :id, worker_id)}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_worker(worker_id), do
    case Registry.lookup(MyApp.Registry, worker_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end

  # Server Callbacks
  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)
end

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start global registry for unique names
      {Registry, keys: :unique, name: MyApp.Registry},
      # Start distributed supervisors on each node
      MyApp.DistributedWorkersSupervisor
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### 3. Cluster Supervisor with Task Supervisor

```elixir
defmodule MyApp.ClusterSupervisor do
  use Supervisor
  require Logger

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    # Start task supervisor for distributed tasks
    task_supervisor = {Task.Supervisor, name: MyApp.TaskSupervisor}

    children = [
      task_supervisor
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def spawn_task(task_module, fun, args \\ []) do
    Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
      apply(task_module, fun, args)
    end)
  end
end
```

### 4. Multi-Region Supervision

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    region = Application.get_env(:my_app, :region)
    node_name = :"my_app-#{region}@#{get_region_host(region)}"

    # Start node with regional name
    {:ok, _pid} = :net_kernel.start(node_name, :longnames)

    children = [
      # Regional supervisors
      {MyApp.DatabaseSupervisor, region: region},
      {MyApp.WorkersSupervisor, region: region}
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_region_host(:us_east), do: "us-east.internal"
  defp get_region_host(:us_west), do: "us-west.internal"
  defp get_region_host(:eu_central), do: "eu-central.internal"
  defp get_region_host(_), do: "default.internal"
end
```

## Global Process Registration Patterns

### 1. Using :global with Supervision

```elixir
defmodule MyApp.GlobalWorker do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  def do_work(data), do: GenServer.call({:global, __MODULE__}, {:do_work, data})

  # Server Callbacks
  @impl true
  def init(opts), do
    Logger.info("Starting global worker on node: #{Node.self()}")
    {:ok, opts}
  end

  @impl true
  def handle_call({:do_work, data}, _from, state) do
    result = process_work(data, state)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.error("Worker exited: #{inspect(reason)}")
    {:stop, reason, state}
  end

  defp process_work(data, opts), do
    # Business logic
    {:processed, data}
  end
end

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Global worker - only one instance across all nodes
      {MyApp.GlobalWorker, []}
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### 2. Using Registry with Distributed Names

```elixir
defmodule MyApp.WorkerPool do
  use DynamicSupervisor
  require Logger

  # Client API
  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  def checkout_worker(pool_name, timeout \\ 5000), do
    case Registry.lookup(MyApp.Registry, pool_name) do
      [{pid, _}] ->
        case GenServer.call(pid, :checkout, timeout) do
          {:ok, worker_pid} -> {:ok, worker_pid}
          {:error, :busy} -> {:error, :no_available_worker}
        end
      [] ->
        {:error, :pool_not_found}
    end
  end

  def checkin_worker(pool_name, worker_pid), do
    case Registry.lookup(MyApp.Registry, pool_name) do
      [{pool_pid, _}] ->
        GenServer.cast(pool_pid, {:checkin, worker_pid})
      [] -> :ok
    end
  end

  # Server Callbacks
  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)
end

defmodule MyApp.Worker do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def checkout(worker_pid), do: GenServer.call(worker_pid, :checkout)
  def checkin(worker_pid), do: GenServer.cast(worker_pid, :checkin)

  @impl true
  def init(opts), do
    pool_name = Keyword.fetch!(opts, :pool_name)
    Registry.register(MyApp.Registry, pool_name, {pool_name, self()})
    {:ok, %{pool_name: pool_name, busy?: false}}
  end

  @impl true
  def handle_call(:checkout, _from, %{busy?: true} = state), do: {:reply, {:error, :busy}, state}
  @impl true
  def handle_call(:checkout, _from, state), do: {:reply, {:ok, self()}, %{state | busy?: true}}

  @impl true
  def handle_cast({:checkin, _worker_pid}, state), do: {:noreply, %{state | busy?: false}}
end
```

## Fault Tolerance Strategies

### 1. Restart Strategy Across Nodes

```elixir
defmodule MyApp.WorkersSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(opts), do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: DynamicSupervisor.init(strategy: :one_for_one)
end

defmodule MyApp.Worker do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))

  @impl true
  def init(opts) do
    Logger.info("Starting worker #{Keyword.fetch!(opts, :name)} on node: #{Node.self()}")
    {:ok, opts}
  end

  @impl true
  def terminate(reason, state) do
    Logger.error("Worker #{state[:name]} terminated: #{inspect(reason)}")
    # Notify cluster supervisor to restart on another node
    MyApp.ClusterSupervisor.handle_worker_down(state[:name])
    :ok
  end
end

defmodule MyApp.ClusterSupervisor do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def handle_worker_down(worker_name), do: GenServer.cast(__MODULE__, {:worker_down, worker_name})

  @impl true
  def init(_opts), do: {:ok, %{}} end

  @impl true
  def handle_cast({:worker_down, worker_name}, state) do
    Logger.info("Worker #{worker_name} down, restarting on available node")
    # Find available node and restart worker
    case find_available_node() do
      {:ok, node} ->
        # Start worker on another node
        case :rpc.call(node, MyApp.Worker, :start_link, [[name: worker_name]], 5_000) do
          {:ok, _pid} ->
            Logger.info("Worker #{worker_name} restarted on node #{node}")
          {:error, reason} ->
            Logger.error("Failed to restart worker #{worker_name}: #{inspect(reason)}")
        end
      {:error, :no_available_nodes} ->
        Logger.error("No available nodes to restart worker #{worker_name}")
    end
    {:noreply, state}
  end

  defp find_available_node(), do
    nodes = [Node.self() | Node.list()]
    case nodes do
      [] -> {:error, :no_available_nodes}
      _ -> {:ok, List.first(nodes)}
    end
  end
end
```

### 2. Handoff Pattern for Process Migration

```elixir
# Use swarms library for process handoff
defp deps do
  [
    {:swarm, "~> 3.0"}
  ]
end

defmodule MyApp.Worker do
  use GenServer
  require Logger

  def start_link(opts), do: Swarm.register_name(__MODULE__, opts, __MODULE__)

  @impl true
  def init(opts), do
    Logger.info("Starting worker on node: #{Node.self()}")
    {:ok, opts}
  end

  @impl true
  def handle_call(:do_work, _from, state) do
    result = process_work(state)
    {:reply, {:ok, result}, state}
  end

  defp process_work(state), do
    # Business logic
    {:processed, state}
  end
end

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start swarm registry
      {Swarm.Registry, name: MyApp.SwarmRegistry},
      # Start worker supervisor
      {MyApp.Worker, [name: :worker_1]},
      {MyApp.Worker, [name: :worker_2]}
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Best Practices

### DO

✅ **Local supervision on each node**: Supervisors run on each node
✅ **Global names for coordination**: Use :global or Registry with unique keys
✅ **Restart on node failure**: Design to restart workers on available nodes
✅ **Use dynamic supervision**: Start/stop workers dynamically
✅ **Monitor node up/down**: Handle node join/leave events
✅ **Implement handoff**: Migrate processes when nodes join/leave
✅ **Use quorum**: Require majority for critical operations
✅ **Test partition scenarios**: Chaos testing with failure injection

### DON'T

❌ **Global supervisor across nodes**: Each node has its own supervision tree
❌ **Assume all nodes are equal**: Some nodes may be slower or unreliable
❌ **Create single points of failure**: Distribute critical processes
❌ **Ignore network partitions**: System must continue despite partial connectivity
❌ **Make blocking cross-node calls**: Use timeouts and handle failures
❌ **Hardcode node names**: Use service discovery (DNS, Kubernetes)
❌ **Forget about clock skew**: Different clocks need synchronization
❌ **Skip testing**: Test distributed scenarios (network partitions, node failures)
❌ **Overuse :global**: It's a bottleneck for global processes

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Use for distributed system design
- **DevOps Engineer**: Use for deployment and configuration
- **QA**: Test distributed scenarios (network partitions, node failures)
- **Security Architect**: Implement secure inter-node communication

### Skills to Reference

- **otp-patterns**: GenServer and Supervisor patterns
- **distributed-systems**: This skill for comprehensive patterns
- **observability**: Monitor node health and performance
- **test-generation**: Write tests for distributed scenarios

### Documentation Links

- **Clustering**: `patterns/clustering_strategies.md` (already created)
- **Mnesia Patterns**: `patterns/mnesia_patterns.md` (to create)
- **Network Partition Handling**: `skills/distributed-systems/SKILL.md` (already created)

---

## Summary

Distributed supervision provides:
- ✅ Local supervision on each node
- ✅ Global process coordination
- ✅ Fault tolerance through supervision
- ✅ Process migration on node failure
- ✅ Load balancing across cluster
- ✅ Handoff for process relocation

**Key**: Design for partial connectivity, use dynamic supervision, and test distributed scenarios.
