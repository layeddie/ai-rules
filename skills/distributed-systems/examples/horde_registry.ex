# Horde Distributed Registry Examples
#
# Horde provides distributed process registries and supervisors that
# maintain consistency across node joins, leaves, and network partitions.
#
# Dependencies:
#   {:horde, "~> 0.9"}
#
# Key features:
# - Distributed process registry (Horde.Registry)
# - Distributed supervisor (Horde.DynamicSupervisor)
# - CRDT-based consistency
# - Automatic conflict resolution

defmodule MyApp.DistributedRegistry do
  @moduledoc """
  Horde-based distributed process registry.

  Provides a global registry that survives network partitions and
  automatically redistributes processes when nodes join/leave.
  """

  use Horde.Registry

  def start_link(_opts) do
    Horde.Registry.start_link(__MODULE__, __MODULE__, keys: :unique)
  end

  @impl true
  def init(_init_arg) do
    Horde.Registry.init(
      keys: :unique,
      members: :auto,
      process_termination_timeout: 5_000
    )
  end

  # Convenience functions
  def via_tuple(name) do
    {:via, Horde.Registry, {__MODULE__, name}}
  end

  def lookup(name) do
    case Horde.Registry.lookup(__MODULE__, name) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def registered?(name) do
    match?({:ok, _}, lookup(name))
  end
end

defmodule MyApp.DistributedSupervisor do
  @moduledoc """
  Horde-based distributed dynamic supervisor.

  Distributes child processes across the cluster and automatically
  restarts them on another node if the current node fails.
  """

  use Horde.DynamicSupervisor

  def start_link(_opts) do
    Horde.DynamicSupervisor.start_link(__MODULE__, __MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Horde.DynamicSupervisor.init(
      strategy: :one_for_one,
      distribution_strategy: Horde.DynamicSupervisor.DistributionStrategy.OneForOne,
      process_termination_timeout: 5_000,
      max_restarts: 1_000,
      max_seconds: 1,
      members: :auto
    )
  end

  # Public API
  def start_child(child_spec) do
    Horde.DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def start_named_child(name, child_spec) do
    # Use via tuple for distributed registration
    spec = Map.put_new(child_spec, :id, name)
    Horde.DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(pid) do
    Horde.DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def which_children do
    Horde.DynamicSupervisor.which_children(__MODULE__)
  end

  def count_children do
    Horde.DynamicSupervisor.count_children(__MODULE__)
  end
end

defmodule MyApp.SingletonSupervisor do
  @moduledoc """
  Horde-based singleton supervisor.

  Ensures exactly one instance of a process runs across the entire cluster.
  If the node running the singleton fails, it automatically restarts on
  another node.
  """

  use Horde.DynamicSupervisor

  def start_link(_opts) do
    Horde.DynamicSupervisor.start_link(__MODULE__, __MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Horde.DynamicSupervisor.init(
      strategy: :one_for_one,
      distribution_strategy: Horde.DynamicSupervisor.DistributionStrategy.OneForOne,
      process_termination_timeout: 5_000,
      members: :auto
    )
  end

  def start_singleton(name, module, args \\ []) do
    child_spec = %{
      id: name,
      start: {module, :start_link, [args ++ [name: via_tuple(name)]]},
      restart: :permanent,
      type: :worker
    }

    # Check if already running
    case MyApp.DistributedRegistry.lookup(name) do
      {:ok, pid} -> {:ok, pid}
      {:error, :not_found} -> start_singleton_child(child_spec)
    end
  end

  defp start_singleton_child(child_spec) do
    case Horde.DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  def via_tuple(name) do
    MyApp.DistributedRegistry.via_tuple(name)
  end
end

defmodule MyApp.DistributedWorker do
  @moduledoc """
  Example worker that uses Horde for distributed registration.

  This worker will be automatically restarted on another node
  if the current node fails.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def do_work(name, data) do
    GenServer.call(via_tuple(name), {:do_work, data})
  end

  defp via_tuple(name) do
    MyApp.DistributedRegistry.via_tuple({:worker, name})
  end

  @impl true
  def init(opts) do
    worker_id = Keyword.fetch!(opts, :worker_id)

    # Register with distributed registry
    case Horde.Registry.register(MyApp.DistributedRegistry, {:worker, worker_id}, self()) do
      {:ok, _} ->
        Logger.info("Worker #{worker_id} started on node #{Node.self()}")
        {:ok, %{worker_id: worker_id, opts: opts}}

      {:error, {:already_registered, pid}} ->
        Logger.warning("Worker #{worker_id} already registered on #{node(pid)}")
        {:stop, :already_registered}
    end
  end

  @impl true
  def handle_call({:do_work, data}, _from, state) do
    Logger.info("Worker #{state.worker_id} processing on #{Node.self()}")
    result = process_data(data)
    {:reply, {:ok, result}, state}
  end

  defp process_data(data) do
    # Simulate work
    Process.sleep(100)
    {:processed, data}
  end
end

# Application setup
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start Horde registries and supervisors
      MyApp.DistributedRegistry,
      MyApp.DistributedSupervisor,
      MyApp.SingletonSupervisor
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Configuration examples
# config/config.exs
# 
# config :my_app,
#   horde_members: [
#     {MyApp.DistributedRegistry, :auto},
#     {MyApp.DistributedSupervisor, :auto},
#     {MyApp.SingletonSupervisor, :auto}
#   ]

# Usage examples:
#
# # Start a distributed worker
# {:ok, pid} = MyApp.DistributedSupervisor.start_child(%{
#   id: :worker_1,
#   start: {MyApp.DistributedWorker, :start_link, [[worker_id: :worker_1]]},
#   restart: :permanent
# })
#
# # Start a singleton process
# {:ok, pid} = MyApp.SingletonSupervisor.start_singleton(
#   :unique_scheduler,
#   MyApp.SchedulerWorker,
#   []
# )
#
# # Look up a process anywhere in the cluster
# {:ok, pid} = MyApp.DistributedRegistry.lookup({:worker, :worker_1})
#
# # The process will automatically migrate if the node fails
