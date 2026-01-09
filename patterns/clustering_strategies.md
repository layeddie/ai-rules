# Clustering Strategies

**Purpose**: Node clustering patterns for Elixir/BEAM distributed applications.

## Quick Start

```elixir
# Start node with name
iex --name app1@127.0.0.1 -S mix

# Start node with cookie
iex --name app1@127.0.0.1 --cookie secret_cookie -S mix

# Connect to another node
Node.connect(:app2@127.0.0.1)

# List connected nodes
Node.list()
```

## Node Discovery Strategies

### 1. Manual Clustering

```elixir
# config/prod.exs
config :my_app,
  nodes: [
    :"app1@host1.internal",
    :"app2@host2.internal",
    :"app3@host3.internal"
  ]

# application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Connect to configured nodes
    nodes = Application.get_env(:my_app, :nodes)
    Enum.each(nodes, &Node.connect/1)
    
    children = [
      MyApp.Supervisor
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to Use**:
- Small, fixed cluster (2-3 nodes)
- Development/testing environments
- Simple use case without dynamic scaling

### 2. DNS-Based Clustering

```elixir
# config/prod.exs
config :libcluster,
  topologies: [
    production: [
      strategy: Cluster.Strategy.DNSPoll,
      config: [
        query: "my-app-headless.default.svc.cluster.local",
        node_basename: "my_app",
        polling_interval: 5_000,
        ip_lookup_mode: :dns
      ]
    ]
  ]

# mix.exs
defp deps do
  [
    {:libcluster, "~> 3.3"}
  ]
end

# application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)
    children = [
      {Cluster.Supervisor, [topologies: topologies]}
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.ClusterSupervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to Use**:
- Kubernetes or DNS-based service discovery
- Dynamic node addition/removal
- Production clusters with service discovery

### 3. Kubernetes Clustering

```elixir
# config/prod.exs
config :libcluster,
  topologies: [
    production: [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config: [
        service: "my-app",
        application_name: :my_app,
        polling_interval: 10_000
      ]
    ]
  ]
```

**When to Use**:
- Kubernetes deployment
- Dynamic pod scaling
- Service discovery via Kubernetes DNS

### 4. Gossip Clustering

```elixir
# config/prod.exs
config :libcluster,
  topologies: [
    production: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: "0.0.0.0",
        multicast_addr: "239.255.255.250",
        multicast_ttl: 1,
        multicast_loop: true
      ]
    ]
  ]
```

**When to Use**:
- Nodes on same network (no DNS)
- Multicast-enabled network
- Development/testing without service discovery

---

## Global Process Registration

### 1. Using :global

```elixir
# Register global process
:global.register_name(:unique_cache, pid)
:global.register_name(:worker_pool, pid)

# Lookup by name
case :global.whereis_name(:unique_cache) do
  pid when is_pid(pid) -> {:ok, pid}
  :undefined -> {:error, :not_found}
end

# Sync operation across all nodes
defmodule MyApp.GlobalCache do
  def get(key) do
    case :global.whereis_name(:cache_worker) do
      pid when is_pid(pid) -> GenServer.call(pid, {:get, key})
      :undefined -> {:error, :not_found}
    end
  end

  def put(key, value) do
    case :global.whereis_name(:cache_worker) do
      pid when is_pid(pid) -> GenServer.cast(pid, {:put, key, value})
      :undefined -> {:error, :not_found}
    end
  end

  def sync_invalidate(key) do
    # Invalidate across all nodes
    :global.trans({:global_cache, self()}, fn ->
      nodes = Node.list()
      Enum.each(nodes, fn node ->
        :rpc.cast(node, MyApp.Cache, :invalidate, [key])
      end)
      :ok
    end)
  end
end
```

### 2. Using Distributed Registry

```elixir
defmodule MyApp.Registry do
  use Registry

  def start_link(opts) do
    opts = Keyword.put_new(opts, :keys, :unique)
    opts = Keyword.put_new(opts, :name, __MODULE__)
    Registry.start_link(opts, opts)
  end

  def register_name(name, pid) do
    case Registry.register(__MODULE__, name, pid) do
      {:ok, _pid} -> :ok
      {:error, _reason} -> {:error, :already_registered}
    end
  end

  def lookup_name(name) do
    case Registry.lookup(__MODULE__, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def unregister_name(name) do
    Registry.unregister(__MODULE__, name)
  end
end

# application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start distributed registry
      {MyApp.Registry, [name: MyApp.Registry]},
      # Start cache
      MyApp.GlobalCache
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

---

## Leadership Election

### 1. Simple Election with :global

```elixir
defmodule MyApp.Leader do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def am_leader?, do: GenServer.call(__MODULE__, :am_leader)
  def elect_leader, do: GenServer.cast(__MODULE__, :elect)

  # Server Callbacks
  @impl true
  def init(opts) do
    Logger.info("Starting leader election")
    {:ok, %{is_leader: false, opts: opts}}
  end

  @impl true
  def handle_call(:am_leader, _from, state) do
    {:reply, state.is_leader, state}
  end

  @impl true
  def handle_cast(:elect, state) do
    # Use :global for leader election
    case :global.set_lock({:leader, self()}, [node()]) do
      true ->
        Logger.info("Node #{Node.self()} is now leader")
        {:noreply, %{state | is_leader: true}}
      false ->
        Logger.info("Node #{Node.self()} is follower")
        {:noreply, %{state | is_leader: false}}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :global, _, _}, state) do
    # Lock lost, try to re-elect
    Logger.warning("Leader lock lost, re-electing")
    {:noreply, state}
  end
end
```

### 2. Raft Consensus (Advanced)

```elixir
# Use a Raft implementation library
defp deps do
  [
    {:raft_fleet, "~> 6.0"}
  ]
end

# Raft-based leader election
defmodule MyApp.RaftLeader do
  use RaftFleet

  def start_link(opts) do
    RaftFleet.start_link(__MODULE__, opts)
  end

  def command(command) do
    RaftFleet.command(__MODULE__, command)
  end

  @impl true
  def handle_command(command, state) do
    # Process Raft-consistent commands
    {:reply, :ok, state}
  end
end
```

---

## Health Monitoring

### Node Health Check

```elixir
defmodule MyApp.NodeMonitor do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get_cluster_status, do: GenServer.call(__MODULE__, :get_status)

  # Server Callbacks
  @impl true
  def init(opts) do
    # Monitor node connections
    :net_kernel.monitor_nodes(true)
    # Schedule periodic health checks
    schedule_health_check(opts[:check_interval] || 10_000)
    {:ok, %{connected_nodes: Node.list(), opts: opts}}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("Node joined: #{node}")
    new_state = %{state | connected_nodes: [node | state.connected_nodes]}
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.warning("Node left: #{node}")
    new_state = %{state | connected_nodes: List.delete(state.connected_nodes, node)}
    {:noreply, handle_node_down(node, new_state)}
  end

  @impl true
  def handle_info(:health_check, state) do
    check_node_health(state.connected_nodes)
    schedule_health_check(state.opts[:check_interval] || 10_000)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      connected_nodes: state.connected_nodes,
      node_count: length(state.connected_nodes),
      current_node: Node.self()
    }
    {:reply, status, state}
  end

  defp schedule_health_check(interval) do
    Process.send_after(self(), :health_check, interval)
  end

  defp check_node_health(nodes) do
    Enum.each(nodes, fn node ->
      case :rpc.call(node, Node, :ping, [], 1_000) do
        :pong -> :ok
        {:badrpc, _reason} ->
          Logger.error("Node health check failed: #{node}")
          # Handle unhealthy node
        end
      end
    end)
  end

  defp handle_node_down(node, state) do
    # Handle graceful degradation
    MyApp.GlobalCache.rebalance(state.connected_nodes)
    MyApp.WorkerSupervisor.restart_workers_on_new_node()
    state
  end
end
```

---

## Best Practices

### DO

✅ **Start with single node**: Test locally before clustering
✅ **Use libcluster**: Let libcluster manage node discovery
✅ **Monitor nodes**: Track node up/down events
✅ **Handle network partitions**: Design for partial connectivity
✅ **Use global names**: :global or Registry with unique keys
✅ **Implement leader election**: Single coordinator for critical operations
✅ **Monitor health**: Periodic health checks across nodes
✅ **Use timeouts**: Timeout RPC calls to avoid blocking

### DON'T

❌ **Hardcode node names**: Use service discovery (DNS, Kubernetes)
❌ **Assume all nodes are equal**: Some nodes may be slower or unreliable
❌ **Ignore network partitions**: System must continue despite partial connectivity
❌ **Make blocking RPC calls**: Use timeouts and handle failures
❌ **Create single points of failure**: Distribute critical processes
❌ **Forget about clock skew**: Different clocks need synchronization
❌ **Skip testing**: Test distributed scenarios (network partitions, node failures)
❌ **Overuse :global**: It's a bottleneck for global processes

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Use for distributed system design
- **DevOps Engineer**: Use for deployment and configuration
- **Security Architect**: Implement secure inter-node communication
- **QA**: Test distributed scenarios

### Skills to Reference

- **otp-patterns**: GenServer and Supervisor patterns
- **observability**: Monitor node health and performance
- **test-generation**: Write tests for distributed scenarios
- **distributed-systems**: This skill for comprehensive patterns

### Documentation Links

- **Distributed Supervision**: `patterns/distributed_supervision.md` (to create)
- **Mnesia Patterns**: `patterns/mnesia_patterns.md` (to create)
- **Network Partition Handling**: `skills/distributed-systems/SKILL.md` (already created)
