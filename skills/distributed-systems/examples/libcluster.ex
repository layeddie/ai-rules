# Libcluster Node Discovery Examples
#
# Libcluster provides automatic node discovery and clustering for Elixir applications.
# It supports multiple strategies: Kubernetes, DNS, Gossip, EPMD, and more.
#
# Dependencies:
#   {:libcluster, "~> 3.3"}
#
# Key strategies:
# - Cluster.Strategy.Kubernetes.DNS - DNS-based discovery in K8s
# - Cluster.Strategy.Kubernetes - K8s API-based discovery
# - Cluster.Strategy.DNSPoll - Generic DNS polling
# - Cluster.Strategy.Gossip - UDP multicast discovery
# - Cluster.Strategy.Epmd - EPMD-based discovery
# - Cluster.Strategy.LocalEpmd - Local development

defmodule MyApp.ClusterConfig do
  @moduledoc """
  Centralized cluster configuration for different environments.
  """

  def topology_configs do
    [
      development: development_topology(),
      kubernetes_dns: kubernetes_dns_topology(),
      kubernetes_api: kubernetes_api_topology(),
      dns_poll: dns_poll_topology(),
      gossip: gossip_topology(),
      epmd: epmd_topology()
    ]
  end

  # Development - connects to local nodes only
  defp development_topology do
    [
      strategy: Cluster.Strategy.LocalEpmd,
      config: [
        hosts: [:"app1@127.0.0.1", :"app2@127.0.0.1"]
      ]
    ]
  end

  # Kubernetes DNS - uses headless service for discovery
  defp kubernetes_dns_topology do
    [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config: [
        service: System.get_env("K8S_SERVICE") || "my-app-headless",
        application_name: :my_app,
        polling_interval: 10_000
      ]
    ]
  end

  # Kubernetes API - uses K8s API for pod discovery
  defp kubernetes_api_topology do
    [
      strategy: Cluster.Strategy.Kubernetes,
      config: [
        kubernetes_ip_lookup_mode: :pods,
        kubernetes_selector: "app=my-app",
        kubernetes_node_basename: "my_app",
        polling_interval: 10_000,
        kube_service_account_path: "/var/run/secrets/kubernetes.io/serviceaccount/token",
        kube_namespace_path: "/var/run/secrets/kubernetes.io/serviceaccount/namespace"
      ]
    ]
  end

  # DNS Poll - generic DNS-based discovery
  defp dns_poll_topology do
    [
      strategy: Cluster.Strategy.DNSPoll,
      config: [
        query: System.get_env("CLUSTER_DNS_QUERY") || "my-app.cluster.local",
        node_basename: :my_app,
        polling_interval: 5_000,
        ip_lookup_mode: :dns
      ]
    ]
  end

  # Gossip - UDP multicast for LAN discovery
  defp gossip_topology do
    [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: "0.0.0.0",
        multicast_addr: "230.1.1.251",
        multicast_ttl: 1,
        secret: System.get_env("CLUSTER_SECRET") || "my_cluster_secret"
      ]
    ]
  end

  # EPMD - for static node lists
  defp epmd_topology do
    [
      strategy: Cluster.Strategy.Epmd,
      config: [
        hosts: [
          :"my_app@10.0.1.1",
          :"my_app@10.0.1.2",
          :"my_app@10.0.1.3"
        ]
      ]
    ]
  end
end

defmodule MyApp.ClusterSupervisor do
  @moduledoc """
  Supervises cluster formation and management.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    topology = get_topology()

    children = [
      {Cluster.Supervisor, [topologies: topology]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_topology do
    env = System.get_env("MIX_ENV") || "dev"
    topology_name = String.to_atom(env)

    case Keyword.get(MyApp.ClusterConfig.topology_configs(), topology_name) do
      nil -> [development: Keyword.get(MyApp.ClusterConfig.topology_configs(), :development)]
      config -> [{topology_name, config}]
    end
  end
end

defmodule MyApp.ClusterManager do
  @moduledoc """
  Provides utilities for cluster management and monitoring.
  """
  require Logger

  def connect(node) do
    case Node.connect(node) do
      true ->
        Logger.info("Connected to node: #{node}")
        {:ok, :connected}

      false ->
        Logger.warning("Failed to connect to node: #{node}")
        {:error, :connection_failed}

      :ignored ->
        Logger.warning("Connection to #{node} ignored (already connected)")
        {:ok, :already_connected}
    end
  end

  def disconnect(node) do
    case Node.disconnect(node) do
      true ->
        Logger.info("Disconnected from node: #{node}")
        :ok

      false ->
        Logger.warning("Failed to disconnect from #{node}")
        {:error, :disconnect_failed}
    end
  end

  def connected_nodes do
    Node.list()
  end

  def all_nodes do
    [Node.self() | Node.list()]
  end

  def node_info(node \\ Node.self()) do
    %{
      node: node,
      is_self: node == Node.self(),
      connected: node in Node.list() or node == Node.self(),
      memory: :rpc.call(node, :erlang, :memory, [:total]),
      processes: :rpc.call(node, Process, :info, [self(), :process_count]),
      uptime: :rpc.call(node, :erlang, :statistics, [:wall_clock])
    }
  end

  def cluster_health do
    nodes = all_nodes()

    %{
      total_nodes: length(nodes),
      nodes:
        Enum.map(nodes, fn node ->
          {node, check_node_health(node)}
        end),
      cluster_size: length(nodes),
      quorum: div(length(nodes), 2) + 1
    }
  end

  defp check_node_health(node) do
    try do
      memory = :rpc.call(node, :erlang, :memory, [:total], 5_000)
      process_count = :rpc.call(node, Process, :info, [self(), :process_count], 5_000)

      %{
        status: :healthy,
        memory: memory,
        process_count: process_count
      }
    catch
      :exit, _ ->
        %{status: :unhealthy, error: :rpc_timeout}
    end
  end

  def ping_all do
    Enum.map(Node.list(), fn node ->
      {node, :rpc.call(node, Node, :ping, [], 5_000)}
    end)
  end
end

defmodule MyApp.NodeMonitor do
  @moduledoc """
  Monitors cluster membership changes and takes action on node up/down events.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Subscribe to node events
    :net_kernel.monitor_nodes(true)

    # Register with libcluster callbacks
    register_callbacks()

    {:ok,
     %{
       nodes: Node.list(),
       callbacks: Keyword.get(opts, :callbacks, []),
       history: []
     }}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("Node joined cluster: #{node}")

    new_state = %{
      state
      | nodes: [node | state.nodes],
        history: [{:up, node, System.system_time()} | state.history]
    }

    # Execute callbacks
    execute_callbacks(:nodeup, node, state.callbacks)

    # Trigger rebalancing
    MyApp.ClusterRebalancer.rebalance()

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.warning("Node left cluster: #{node}")

    new_state = %{
      state
      | nodes: List.delete(state.nodes, node),
        history: [{:down, node, System.system_time()} | state.history]
    }

    # Execute callbacks
    execute_callbacks(:nodedown, node, state.callbacks)

    # Trigger failover
    MyApp.ClusterRebalancer.handle_node_failure(node)

    {:noreply, new_state}
  end

  defp register_callbacks do
    # Optional: Register custom callbacks with libcluster
    :ok
  end

  defp execute_callbacks(event, node, callbacks) do
    Enum.each(callbacks, fn
      {^event, callback} -> callback.(node)
      callback when is_function(callback, 2) -> callback.(event, node)
      _ -> :ok
    end)
  end
end

defmodule MyApp.ClusterRebalancer do
  @moduledoc """
  Rebalances distributed processes when cluster membership changes.
  """
  require Logger

  def rebalance do
    nodes = [Node.self() | Node.list()]

    Logger.info("Rebalancing across #{length(nodes)} nodes")

    # Get all registered processes
    processes = MyApp.DistributedSupervisor.which_children()

    # Calculate ideal distribution
    target_per_node = div(length(processes), length(nodes))

    # Redistribute if needed
    redistribute_processes(processes, nodes, target_per_node)
  end

  def handle_node_failure(failed_node) do
    Logger.warning("Handling failure of node: #{failed_node}")

    # Horde automatically restarts processes on other nodes
    # Additional cleanup can be done here

    :ok
  end

  defp redistribute_processes(processes, nodes, target) do
    # Get current distribution
    distribution = Enum.group_by(processes, fn {_, pid, _, _} -> node(pid) end)

    # Calculate which nodes have too many/few processes
    over_loaded =
      Enum.filter(nodes, fn node ->
        length(Map.get(distribution, node, [])) > target
      end)

    under_loaded =
      Enum.filter(nodes, fn node ->
        length(Map.get(distribution, node, [])) < target
      end)

    # Move processes from over-loaded to under-loaded nodes
    Enum.zip(over_loaded, under_loaded)
    |> Enum.each(fn {from_node, to_node} ->
      move_processes(from_node, to_node, distribution, target)
    end)
  end

  defp move_processes(from_node, to_node, distribution, target) do
    from_processes = Map.get(distribution, from_node, [])
    to_count = length(Map.get(distribution, to_node, []))
    to_move = min(length(from_processes) - target, target - to_count)

    # Horde handles the actual migration
    Logger.info("Moving #{to_move} processes from #{from_node} to #{to_node}")
  end
end

# Configuration for different environments

# config/dev.exs
# config :my_app, :cluster,
#   topology: :development

# config/prod.exs (Kubernetes)
# config :my_app, :cluster,
#   topology: :kubernetes_dns,
#   service: "my-app-headless"

# config/prod.exs (DNS)
# config :my_app, :cluster,
#   topology: :dns_poll,
#   query: "my-app.cluster.local"

# Usage in Application.ex:
#
# def start(_type, _args) do
#   children = [
#     MyApp.ClusterSupervisor,
#     MyApp.NodeMonitor,
#     # ... other children
#   ]
#
#   Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
# end
