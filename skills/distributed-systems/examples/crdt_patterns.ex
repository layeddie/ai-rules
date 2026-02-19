# CRDT (Conflict-Free Replicated Data Types) Patterns
#
# CRDTs provide eventual consistency without coordination.
# They automatically resolve conflicts in a deterministic way.
#
# Libraries:
#   {:delta_crdt, "~> 0.3"} - Delta CRDT implementation
#   {:state_crdt, "~> 0.1"} - State-based CRDTs
#
# Key CRDT types:
# - GCounter: Grow-only counter
# - PNCounter: Increment/decrement counter
# - GSet: Grow-only set
# - ORSet: Observed-remove set
# - LWWRegister: Last-writer-wins register
# - MVRegister: Multi-value register

defmodule MyApp.CrdtTypes do
  @moduledoc """
  Documentation for common CRDT types and their use cases.
  """

  # G-Counter (Grow-only Counter)
  # Each node maintains its own count, total is sum of all counts
  # Use case: Page views, download counts, likes
  defmodule GCounter do
    def new, do: %{}

    def increment(counter, node) do
      current = Map.get(counter, node, 0)
      Map.put(counter, node, current + 1)
    end

    def value(counter) do
      counter |> Map.values() |> Enum.sum()
    end

    def merge(counter1, counter2) do
      Map.merge(counter1, counter2, fn _k, v1, v2 -> max(v1, v2) end)
    end
  end

  # PN-Counter (Positive-Negative Counter)
  # Two G-Counters: one for increments, one for decrements
  # Use case: Account balance, votes (up/down), inventory
  defmodule PNCounter do
    def new, do: %{p: %{}, n: %{}}

    def increment(counter, node) do
      %{counter | p: GCounter.increment(counter.p, node)}
    end

    def decrement(counter, node) do
      %{counter | n: GCounter.increment(counter.n, node)}
    end

    def value(counter) do
      GCounter.value(counter.p) - GCounter.value(counter.n)
    end

    def merge(counter1, counter2) do
      %{
        p: GCounter.merge(counter1.p, counter2.p),
        n: GCounter.merge(counter1.n, counter2.n)
      }
    end
  end

  # G-Set (Grow-only Set)
  # Set that only supports additions
  # Use case: Tags, unique visitors, completed tasks
  defmodule GSet do
    def new, do: MapSet.new()

    def add(set, element) do
      MapSet.put(set, element)
    end

    def member?(set, element) do
      MapSet.member?(set, element)
    end

    def size(set) do
      MapSet.size(set)
    end

    def merge(set1, set2) do
      MapSet.union(set1, set2)
    end
  end

  # OR-Set (Observed-Remove Set)
  # Supports both add and remove with unique tags
  # Use case: Shopping cart, active users, collaborative lists
  defmodule ORSet do
    def new, do: %{elements: %{}, tombstones: MapSet.new()}

    def add(set, element, tag) do
      tags = Map.get(set.elements, element, MapSet.new())
      new_tags = MapSet.put(tags, tag)
      %{set | elements: Map.put(set.elements, element, new_tags)}
    end

    def remove(set, element) do
      tags = Map.get(set.elements, element, MapSet.new())
      new_tombstones = MapSet.union(set.tombstones, tags)
      %{set | elements: Map.delete(set.elements, element), tombstones: new_tombstones}
    end

    def member?(set, element) do
      case Map.get(set.elements, element) do
        nil -> false
        tags -> MapSet.size(tags) > 0
      end
    end

    def merge(set1, set2) do
      # Merge elements
      merged_elements =
        Map.merge(set1.elements, set2.elements, fn _k, tags1, tags2 ->
          MapSet.union(tags1, tags2)
        end)

      # Merge tombstones
      merged_tombstones = MapSet.union(set1.tombstones, set2.tombstones)

      # Remove tombstoned tags from elements
      cleaned_elements =
        Enum.reduce(merged_elements, %{}, fn {element, tags}, acc ->
          alive_tags = MapSet.difference(tags, merged_tombstones)

          if MapSet.size(alive_tags) > 0 do
            Map.put(acc, element, alive_tags)
          else
            acc
          end
        end)

      %{elements: cleaned_elements, tombstones: merged_tombstones}
    end
  end

  # LWW-Register (Last-Writer-Wins Register)
  # Single value with timestamp, last update wins
  # Use case: User profile fields, settings, configuration
  defmodule LWWRegister do
    def new, do: %{value: nil, timestamp: 0, node: nil}

    def set(register, value, timestamp, node) do
      if timestamp > register.timestamp do
        %{value: value, timestamp: timestamp, node: node}
      else
        register
      end
    end

    def get(register) do
      register.value
    end

    def merge(register1, register2) do
      if register1.timestamp > register2.timestamp do
        register1
      else
        register2
      end
    end
  end
end

defmodule MyApp.DistributedCounter do
  @moduledoc """
  Distributed counter using PN-Counter CRDT.

  Can be incremented or decremented from any node,
  and values will eventually converge.
  """

  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def increment(name \\ __MODULE__, amount \\ 1) do
    GenServer.call(name, {:increment, amount})
  end

  def decrement(name \\ __MODULE__, amount \\ 1) do
    GenServer.call(name, {:decrement, amount})
  end

  def value(name \\ __MODULE__) do
    GenServer.call(name, :value)
  end

  def merge(name \\ __MODULE__, other_counter) do
    GenServer.call(name, {:merge, other_counter})
  end

  @impl true
  def init(opts) do
    node = Keyword.get(opts, :node, Node.self())

    state = %{
      counter: MyApp.CrdtTypes.PNCounter.new(),
      node: node,
      subscribers: []
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:increment, amount}, _from, state) do
    new_counter =
      Enum.reduce(1..amount, state.counter, fn _, acc ->
        MyApp.CrdtTypes.PNCounter.increment(acc, state.node)
      end)

    new_state = %{state | counter: new_counter}
    notify_subscribers(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:decrement, amount}, _from, state) do
    new_counter =
      Enum.reduce(1..amount, state.counter, fn _, acc ->
        MyApp.CrdtTypes.PNCounter.decrement(acc, state.node)
      end)

    new_state = %{state | counter: new_counter}
    notify_subscribers(new_state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:value, _from, state) do
    value = MyApp.CrdtTypes.PNCounter.value(state.counter)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:merge, other_counter}, _from, state) do
    new_counter = MyApp.CrdtTypes.PNCounter.merge(state.counter, other_counter)
    new_state = %{state | counter: new_counter}
    notify_subscribers(new_state)
    {:reply, :ok, new_state}
  end

  defp notify_subscribers(state) do
    value = MyApp.CrdtTypes.PNCounter.value(state.counter)

    Enum.each(state.subscribers, fn pid ->
      send(pid, {:counter_updated, value})
    end)
  end
end

defmodule MyApp.DistributedSet do
  @moduledoc """
  Distributed set using OR-Set CRDT.

  Supports add and remove operations that converge correctly.
  """

  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def add(name \\ __MODULE__, element) do
    GenServer.call(name, {:add, element})
  end

  def remove(name \\ __MODULE__, element) do
    GenServer.call(name, {:remove, element})
  end

  def member?(name \\ __MODULE__, element) do
    GenServer.call(name, {:member?, element})
  end

  def to_list(name \\ __MODULE__) do
    GenServer.call(name, :to_list)
  end

  def merge(name \\ __MODULE__, other_set) do
    GenServer.call(name, {:merge, other_set})
  end

  @impl true
  def init(opts) do
    state = %{
      set: MyApp.CrdtTypes.ORSet.new(),
      subscribers: []
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:add, element}, _from, state) do
    tag = generate_tag()
    new_set = MyApp.CrdtTypes.ORSet.add(state.set, element, tag)
    new_state = %{state | set: new_set}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:remove, element}, _from, state) do
    new_set = MyApp.CrdtTypes.ORSet.remove(state.set, element)
    new_state = %{state | set: new_set}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:member?, element}, _from, state) do
    result = MyApp.CrdtTypes.ORSet.member?(state.set, element)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:to_list, _from, state) do
    list = Map.keys(state.set.elements)
    {:reply, list, state}
  end

  @impl true
  def handle_call({:merge, other_set}, _from, state) do
    new_set = MyApp.CrdtTypes.ORSet.merge(state.set, other_set)
    new_state = %{state | set: new_set}
    {:reply, :ok, new_state}
  end

  defp generate_tag do
    {Node.self(), System.unique_integer([:positive, :monotonic])}
  end
end

defmodule MyApp.CrdtReplicator do
  @moduledoc """
  Replicates CRDT state across cluster nodes using anti-entropy.
  """

  use GenServer
  require Logger

  @replication_interval 5_000

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    crdt_modules = Keyword.get(opts, :crdt_modules, [])

    # Subscribe to node events
    :net_kernel.monitor_nodes(true)

    # Schedule periodic replication
    schedule_replication()

    state = %{
      crdt_modules: crdt_modules,
      known_nodes: Node.list()
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:replicate, state) do
    replicate_to_nodes(state.known_nodes, state.crdt_modules)
    schedule_replication()
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodeup, node}, state) do
    Logger.info("Node #{node} joined, replicating state")
    replicate_to_node(node, state.crdt_modules)
    {:noreply, %{state | known_nodes: [node | state.known_nodes]}}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    {:noreply, %{state | known_nodes: List.delete(state.known_nodes, node)}}
  end

  @impl true
  def handle_info({:crdt_state, from_node, module, state_data}, state) do
    Logger.debug("Received CRDT state from #{from_node} for #{module}")

    # Merge incoming state
    case module.merge(module, state_data) do
      :ok -> :ok
      error -> Logger.warning("Failed to merge state: #{inspect(error)}")
    end

    {:noreply, state}
  end

  defp schedule_replication do
    Process.send_after(self(), :replicate, @replication_interval)
  end

  defp replicate_to_nodes(nodes, crdt_modules) do
    Enum.each(nodes, fn node ->
      replicate_to_node(node, crdt_modules)
    end)
  end

  defp replicate_to_node(node, crdt_modules) do
    Enum.each(crdt_modules, fn module ->
      case get_crdt_state(module) do
        {:ok, state_data} ->
          send_to_node(node, {:crdt_state, Node.self(), module, state_data})

        _ ->
          :ok
      end
    end)
  end

  defp get_crdt_state(module) do
    # Get current state from CRDT module
    # Implementation depends on CRDT module API
    {:ok, %{}}
  end

  defp send_to_node(node, message) do
    # Send state to remote node
    :rpc.cast(node, __MODULE__, :receive_state, [message])
  end
end

# DeltaCrdt integration example (production)
#
# defmodule MyApp.DistributedMap do
#   use DeltaCrdt
#
#   def start_link(opts) do
#     DeltaCrdt.start_link(__MODULE__, opts)
#   end
#
#   def put(map, key, value) do
#     DeltaCrdt.put(map, key, value)
#   end
#
#   def get(map, key) do
#     DeltaCrdt.get(map, key)
#   end
#
#   def delete(map, key) do
#     DeltaCrdt.delete(map, key)
#   end
# end
#
# # Configuration
# config :my_app, MyApp.DistributedMap,
#   crdt: DeltaCrdt.AWLWWMap,
#   sync_interval: 5_000,
#   max_sync_size: 1_000
#
# # Usage
# {:ok, map} = MyApp.DistributedMap.start_link(name: :my_map)
# MyApp.DistributedMap.put(:my_map, "user:1", %{name: "Alice"})
# MyApp.DistributedMap.get(:my_map, "user:1")  # %{name: "Alice"}
