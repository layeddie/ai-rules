# Advanced Distributed Systems Patterns

This document covers advanced patterns for building robust distributed systems on BEAM/OTP.

## Table of Contents

1. [Horde Distributed Registry](#horde-distributed-registry)
2. [Raft Consensus](#raft-consensus)
3. [Event Sourcing with CQRS](#event-sourcing-with-cqrs)
4. [CRDTs for Conflict Resolution](#crdts-for-conflict-resolution)
5. [Multi-Region Deployment](#multi-region-deployment)
6. [Partition Tolerance Strategies](#partition-tolerance-strategies)

---

## Horde Distributed Registry

### Problem

Need global process registration that survives network partitions and node failures.

### Solution

Use Horde for distributed process registries and supervisors.

### Implementation

```elixir
# 1. Define the registry
defmodule MyApp.Registry do
  use Horde.Registry

  def start_link(_opts) do
    Horde.Registry.start_link(__MODULE__, __MODULE__, [keys: :unique])
  end

  @impl true
  def init(_init_arg) do
    Horde.Registry.init(keys: :unique, members: :auto)
  end
end

# 2. Define distributed supervisor
defmodule MyApp.DistributedSupervisor do
  use Horde.DynamicSupervisor

  def start_link(_opts) do
    Horde.DynamicSupervisor.start_link(__MODULE__, __MODULE__, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Horde.DynamicSupervisor.init(
      strategy: :one_for_one,
      distribution_strategy: Horde.DynamicSupervisor.DistributionStrategy.OneForOne,
      members: :auto
    )
  end
end

# 3. Use via tuples for registration
defmodule MyApp.Worker do
  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(name))
  end

  defp via_tuple(name) do
    {:via, Horde.Registry, {MyApp.Registry, {:worker, name}}}
  end
end
```

### Trade-offs

| Pros | Cons |
|------|------|
| Survives partitions | Higher memory usage |
| Automatic failover | Complex debugging |
| CRDT-based consistency | Not for massive scale |

---

## Raft Consensus

### Problem

Need strong consistency and leader-based coordination across nodes.

### Solution

Implement Raft consensus algorithm using :ra library.

### When to Use

- Distributed locking with guarantees
- Configuration management
- Leader election for critical operations
- Atomic multi-key operations

### Implementation

```elixir
# 1. Define state machine
defmodule MyApp.RaftStateMachine do
  @behaviour :ra_machine

  @impl true
  def init(_config), do: %{}

  @impl true
  def apply(_meta, command, state) do
    case command do
      {:put, key, value} ->
        {{:ok, key}, Map.put(state, key, value)}
        
      {:get, key} ->
        {{:ok, Map.get(state, key)}, state}
        
      {:delete, key} ->
        {{:ok, key}, Map.delete(state, key)}
    end
  end

  @impl true
  def state_enter(_term, _state), do: :ok
end

# 2. Start cluster
defmodule MyApp.RaftCluster do
  @cluster_name :my_raft_cluster

  def start_cluster(nodes) do
    :ra.start_cluster(
      @cluster_name,
      {:module, MyApp.RaftStateMachine, []},
      Enum.map(nodes, fn node -> %{id: node} end),
      %{}
    )
  end

  def put(key, value) do
    :ra.process_command(@cluster_name, {:put, key, value}, 5_000)
  end

  def get(key) do
    :ra.local_query(@cluster_name, {:get, key}, 5_000)
  end
end
```

### Raft Guarantees

1. **Election Safety**: At most one leader per term
2. **Leader Append-Only**: Leader never overwrites/deletes entries
3. **Log Matching**: Same index/term means same command
4. **Leader Completeness**: Committed entries present in future leaders
5. **State Machine Safety**: Nodes apply same commands at same index

---

## Event Sourcing with CQRS

### Problem

Need complete audit trail, time-travel debugging, and complex domain modeling.

### Solution

Store all changes as immutable events, separate read/write models.

### Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Command   │────▶│  Aggregate   │────▶│    Event    │
│   Handler   │     │   (Write)    │     │    Store    │
└─────────────┘     └──────────────┘     └──────┬──────┘
                                               │
                    ┌──────────────┐           │
                    │  Projection  │◀──────────┘
                    │   (Read)     │
                    └──────────────┘
```

### Implementation

```elixir
# 1. Define events (immutable facts)
defmodule MyApp.Events do
  defmodule AccountOpened do
    defstruct [:account_id, :owner_id, :initial_balance, :opened_at]
  end

  defmodule MoneyDeposited do
    defstruct [:account_id, :amount, :balance, :deposited_at]
  end

  defmodule MoneyWithdrawn do
    defstruct [:account_id, :amount, :balance, :withdrawn_at]
  end
end

# 2. Define aggregate
defmodule MyApp.BankAccount do
  defstruct [:id, :status, :balance, :owner_id]

  def execute(%__MODULE__{status: :closed}, %OpenAccount{} = cmd) do
    {:ok, [%Events.AccountOpened{
      account_id: cmd.account_id,
      owner_id: cmd.owner_id,
      initial_balance: cmd.initial_balance,
      opened_at: DateTime.utc_now()
    }]}
  end

  def execute(%__MODULE__{status: :open} = state, %DepositMoney{amount: amount}) do
    {:ok, [%Events.MoneyDeposited{
      account_id: state.id,
      amount: amount,
      balance: state.balance + amount,
      deposited_at: DateTime.utc_now()
    }]}
  end

  def apply(state, %Events.AccountOpened{} = event) do
    %__MODULE__{
      id: event.account_id,
      status: :open,
      balance: event.initial_balance,
      owner_id: event.owner_id
    }
  end

  def apply(state, %Events.MoneyDeposited{balance: balance}) do
    %{state | balance: balance}
  end
end

# 3. Define projection (read model)
defmodule MyApp.AccountSummary do
  use GenServer

  def init(_) do
    # Subscribe to events
    EventStore.subscribe_to_all(self())
    {:ok, %{accounts: %{}}}
  end

  def handle_info({:events, events}, state) do
    new_state = Enum.reduce(events, state, &apply_event/2)
    {:noreply, new_state}
  end

  defp apply_event(%Events.AccountOpened{} = e, state) do
    account = %{id: e.account_id, balance: e.initial_balance}
    put_in(state, [:accounts, e.account_id], account)
  end
end
```

### Benefits

- Complete audit trail
- Time-travel (replay to any point)
- Easy debugging
- Flexible read models
- Event replay for new projections

---

## CRDTs for Conflict Resolution

### Problem

Need eventual consistency without coordination. Handle conflicts automatically.

### Solution

Use Conflict-Free Replicated Data Types.

### CRDT Types Decision Tree

```
Need a counter?
├── Only increments? → G-Counter
├── Need decrement? → PN-Counter
└── Need precision? → Observed-Remove Counter

Need a set?
├── Only additions? → G-Set
├── Add and remove? → OR-Set
└── Need ordering? → Sequence CRDT

Need a map/register?
├── Last write wins? → LWW-Register
├── Keep all values? → MV-Register
└── Nested structure? → LWW-Map / OR-Map
```

### Implementation

```elixir
# PN-Counter (supports increment/decrement)
defmodule PNCounter do
  defstruct p: %{}, n: %{}  # positive/negative counts per node

  def increment(counter, node, amount \\ 1) do
    %{counter | p: Map.update(counter.p, node, amount, &(&1 + amount))}
  end

  def decrement(counter, node, amount \\ 1) do
    %{counter | n: Map.update(counter.n, node, amount, &(&1 + amount))}
  end

  def value(%{p: p, n: n}) do
    Enum.sum(Map.values(p)) - Enum.sum(Map.values(n))
  end

  def merge(c1, c2) do
    %__MODULE__{
      p: merge_max(c1.p, c2.p),
      n: merge_max(c1.n, c2.n)
    }
  end

  defp merge_max(m1, m2) do
    Map.merge(m1, m2, fn _k, v1, v2 -> max(v1, v2) end)
  end
end

# OR-Set (observed-remove set)
defmodule ORSet do
  defstruct elements: %{}, tombstones: MapSet.new()

  def add(set, element, tag) do
    tags = Map.get(set.elements, element, MapSet.new())
    %{set | elements: Map.put(set.elements, element, MapSet.put(tags, tag))}
  end

  def remove(set, element) do
    tags = Map.get(set.elements, element, MapSet.new())
    %{set |
      elements: Map.delete(set.elements, element),
      tombstones: MapSet.union(set.tombstones, tags)
    }
  end

  def merge(s1, s2) do
    # Merge elements and tombstones
    merged_elements = merge_tags(s1.elements, s2.elements)
    merged_tombstones = MapSet.union(s1.tombstones, s2.tombstones)
    
    # Remove tombstoned tags
    cleaned = clean_tombstoned(merged_elements, merged_tombstones)
    
    %__MODULE__{elements: cleaned, tombstones: merged_tombstones}
  end
end
```

### CRDT Libraries

- **DeltaCrdt** - Efficient delta-state CRDTs
- **state_crdt** - State-based CRDTs
- **meck** - For testing

---

## Multi-Region Deployment

### Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   US-East       │         │   US-West       │
│  ┌───────────┐  │         │  ┌───────────┐  │
│  │  Cluster  │◀─┼─────────┼─▶│  Cluster  │  │
│  └───────────┘  │  Async  │  └───────────┘  │
│       │         │ Replication      │        │
│  ┌───────────┐  │         │  ┌───────────┐  │
│  │  Database │  │         │  │  Database │  │
│  └───────────┘  │         │  └───────────┘  │
└─────────────────┘         └─────────────────┘
```

### Implementation

```elixir
# Region-aware configuration
config :my_app, :regions,
  us_east: [
    nodes: [:"app@10.0.1.1", :"app@10.0.1.2"],
    database: "us-east-db.internal"
  ],
  us_west: [
    nodes: [:"app@10.0.2.1", :"app@10.0.2.2"],
    database: "us-west-db.internal"
  ]

# Regional cluster strategy
config :libcluster,
  topologies: [
    local: [
      strategy: Cluster.Strategy.Kubernetes.DNS,
      config: [service: "my-app-local"]
    ]
  ]

# Cross-region replication
defmodule MyApp.CrossRegionReplicator do
  use GenServer

  def init(_) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "data:changes")
    {:ok, %{regions: [:us_west, :eu_west]}}
  end

  def handle_info({:data_change, key, value}, state) do
    # Replicate to other regions asynchronously
    Task.async_stream(state.regions, fn region ->
      replicate_to_region(region, key, value)
    end)
    {:noreply, state}
  end
end
```

---

## Partition Tolerance Strategies

### Strategy 1: Graceful Degradation

```elixir
defmodule MyApp.UserService do
  def get_user(id) do
    case local_cache_lookup(id) do
      {:ok, user} -> {:ok, user}
      :miss -> fetch_with_fallback(id)
    end
  end

  defp fetch_with_fallback(id) do
    case remote_fetch(id) do
      {:ok, user} ->
        cache_locally(id, user)
        {:ok, user}
        
      {:error, :timeout} ->
        # Return stale cache if available
        get_stale_cache(id) || {:error, :unavailable}
    end
  end
end
```

### Strategy 2: Circuit Breaker

```elixir
defmodule MyApp.CircuitBreaker do
  use GenStateMachine

  def init(_) do
    {:ok, :closed, %{failures: 0, last_failure: nil}}
  end

  def handle_event(:call, {:call, remote_fn}, :closed, state) do
    case remote_fn.() do
      {:ok, result} ->
        {:next_state, :closed, %{state | failures: 0}, {:reply, {:ok, result}}}
        
      {:error, _} = error ->
        new_state = %{state | failures: state.failures + 1}
        if new_state.failures >= 5 do
          {:next_state, :open, new_state, {:reply, error}}
        else
          {:next_state, :closed, new_state, {:reply, error}}
        end
    end
  end

  def handle_event(:call, _, :open, state) do
    if should_try_half_open?(state) do
      {:next_state, :half_open, state, {:reply, {:error, :circuit_open}}}
    else
      {:keep_state, state, {:reply, {:error, :circuit_open}}}
    end
  end
end
```

### Strategy 3: Saga for Distributed Transactions

```elixir
defmodule MyApp.Saga do
  def execute(steps) do
    case execute_forward(steps, []) do
      {:ok, results} -> 
        {:ok, results}
        
      {:error, failed_step, executed} ->
        # Compensate in reverse order
        compensate(executed)
        {:error, failed_step}
    end
  end

  defp execute_forward([], results), do: {:ok, Enum.reverse(results)}
  defp execute_forward([{_name, forward, _compensate} | rest], results) do
    case forward.() do
      {:ok, result} -> execute_forward(rest, [result | results])
      {:error, _} = error -> {:error, error, results}
    end
  end

  defp compensate(executed) do
    Enum.each(executed, fn {:compensate, compensate_fn} ->
      compensate_fn.()
    end)
  end
end

# Usage
MyApp.Saga.execute([
  {:reserve_inventory, &reserve_item/0, &release_item/0},
  {:charge_payment, &charge_card/0, &refund_card/0},
  {:ship_order, &create_shipment/0, &cancel_shipment/0}
])
```

---

## Decision Matrix

| Requirement | Solution |
|-------------|----------|
| Global process registry | Horde.Registry |
| Distributed supervision | Horde.DynamicSupervisor |
| Strong consistency | Raft (:ra library) |
| Event sourcing | Commanded + EventStore |
| High availability | CRDTs (DeltaCrdt) |
| Simple clustering | libcluster |
| Cross-region sync | Async replication + CRDTs |
| Distributed transactions | Sagas |
| Fault tolerance | Circuit breakers + fallbacks |

---

## Further Reading

- [Horde Documentation](https://hexdocs.pm/horde/)
- [Raft Paper](https://raft.github.io/raft.pdf)
- [CRDTs for Non-Academics](https://lars.hupel.info/topics/crdt/01-intro/)
- [Commanded Documentation](https://hexdocs.pm/commanded/)
- [libcluster Strategies](https://hexdocs.pm/libcluster/)
