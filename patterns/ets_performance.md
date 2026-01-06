# ETS Performance and GenServer Decision Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: codesearch + Freshcode.it benchmarks (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Deciding between ETS, GenServer, Agent, or `:persistent_term`
- Optimizing read-heavy workloads
- Caching strategies
- Performance benchmarking approaches

❌ **DON'T use this file when**:
- Simple stateless operations (use functions/structs)
- Low-read, low-write workloads (use GenServer with Agent)
- One-time computations (use Task.async)
- Memory-constrained environments (avoid ETS)

**See also**:
- `genserver.md` - GenServer patterns
- `otp_supervisor.md` - Supervisor strategies
- `concurrent_tasks.md` - Task vs Agent vs GenServer

---

## Pattern 1: ETS vs GenServer Decision Matrix

**Use Case | Recommendation | Reason | Performance Impact |
|-----------|----------------|---------|-------------------|
| High read, low write | ETS table | 2.14x faster than GenServer |
| Read + write in one op | GenServer with Agent | Maintains transaction safety |
| Complex state logic | GenServer | Easier to reason about behavior |
| Simple caching | Agent or `:persistent_term` | Minimal overhead |
| Shared mutable state | ETS table | Fast concurrent access |

✅ **ETS Example** (read-heavy workload):
```elixir
defmodule UserCache do
  @table :users_cache
  @opts [:set, :protected, :named_table, read_concurrency: true, write_concurrency: true]

  def init do
    :ets.new(@table, @opts)
  end

  def get(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, user}] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end

  def put(user_id, user) do
    :ets.insert(@table, {user_id, user})
  end
end
```

**Performance**: 5.22 M ops/sec (Freshcode.it benchmark)

---

## Pattern 2: GenServer with Agent for Read-Write

**Problem**: Need fast reads and writes together

✅ **Solution**: GenServer with Agent for cache

```elixir
defmodule CacheServer do
  use GenServer

  def start_link do
    {:ok, agent_pid} = Agent.start_link(fn -> %{})
    GenServer.start_link(__MODULE__, agent_pid, name: __MODULE__)
  end

  def init(agent_pid) do
    {:ok, %{agent: agent_pid}}
  end

  def handle_call(:get, _from, state) do
    value = Agent.get(state.agent, fn map -> Map.get(map, :data))
    {:reply, value, state}
  end

  def handle_cast({:put, key, value}, state) do
    Agent.update(state.agent, fn map -> Map.put(map, key, value))
    {:noreply, state}
  end
end
```

**Performance**: Combines GenServer safety with Agent speed

---

## Pattern 3: Persistent Term for Read-Only Shared State

**Problem**: Configuration that changes rarely, read frequently

✅ **Solution**: Use `:persistent_term`

```elixir
defmodule AppConfig do
  def get(:app_name), do: :persistent_term.get(:app_name, "default_app")

  def set(key, value) do
    :persistent_term.put(key, value)
  end
end
```

**Performance**: O(1) access time, suitable for global configuration

**Reference**: Elixir documentation on `:persistent_term`

---

## Pattern 4: ETS Table Options and Performance

**Problem**: Default ETS options may not be optimal

✅ **Solution**: Choose right table type and options

**Table Types**:
- `:set` - Key-value, unique keys (default)
- `:ordered_set` - Key-value, ordered iteration
- `:bag` - Multi-value per key (duplicates allowed)
- `:duplicate_bag` - Multi-value, ordered by insertion time

**Performance Options**:
- `read_concurrency: true` - Allow parallel reads
- `write_concurrency: true` - Allow parallel writes
- `compressed` - Trade CPU for memory savings
- `protected` - Only owner can write

✅ **Example** (optimized for concurrent reads):
```elixir
defmodule UserCache do
  @opts [
    :set,
    :protected,
    :named_table,
    read_concurrency: true,
    write_concurrency: true
  ]

  def init do
    :ets.new(:users, @opts)
  end
end
```

**Reference**: Freshcode.it - ETS performance benchmarks

---

## Pattern 5: GenServer vs Task for One-Off Operations

**Problem**: GenServer overhead for one-off tasks

✅ **Solution**: Use Task.async for fire-and-forget

```elixir
# Wrong: GenServer
defmodule BadWorker do
  use GenServer

  def handle_call(:one_off_task, _from, state) do
    result = expensive_operation()
    {:reply, result, state}  # ❌ Process stays alive
  end
end

# Correct: Task
defmodule GoodWorker do
  def one_off_task do
    Task.async(fn -> expensive_operation() end)
    # ✅ Process exits when done
  end
end
```

**Performance**: Task has lower overhead than GenServer

**Reference**: `concurrent_tasks.md` - Task vs GenServer patterns

---

## Pattern 6: Memory Management in ETS

**Problem**: ETS can consume significant memory

✅ **Solution**: Use memory-efficient patterns

```elixir
# Compressed ETS for memory savings
:ets.new(:cache, [:set, :compressed, :named_table])

# Periodic cleanup
defmodule CacheManager do
  use GenServer

  def init do
    Process.send_after(self(), :cleanup, 60_000)  # 1 minute
    {:ok, %{entries: %{}}}
  end

  def handle_info(:cleanup, state) do
    :ets.delete_all_objects(:cache)
    {:noreply, state}
  end
end
```

**Reference**: Elixir documentation on ETS memory management

---

## Pattern 7: Benchmarking Before Optimizing

**Problem**: Optimize without measuring first

✅ **Solution**: Use profiling tools

```elixir
# 1. Benchmark with Benchee
mix benchee run script/benchmarks.exs

# 2. Profile with :fprof
:fprof.apply(&MyApp.work, [procm])
# :fprof.stop()

# 3. Use :observer
:observer.start()
```

**Key Principle**: "Instrument first, optimise second" (Freshcode.it)

**Reference**: Freshcode.it - GenServer performance guide

---

## Pattern 8: Large Data Structures in ETS

**Problem**: Storing large objects in ETS

✅ **Solution**: Use references or binary patterns

```elixir
# Option 1: ETS of references
:ets.insert(:cache, {:user_id, :persistent_term})

# Option 2: Binary storage
:ets.insert(:cache, {:data_id, :binary.copy(data)})
```

**Reference**: Elixir documentation

---

## Testing Patterns for This File

### Benchmarking ETS vs GenServer

```elixir
defmodule CacheBench do
  use Benchee

  bench "ETS read" do
    :ets.new(:bench_table, [:set])
    Enum.each(1..10_000, fn i -> :ets.insert(:bench_table, {i, i}))
    :ets.lookup(:bench_table, 5000)
  end

  bench "GenServer read" do
    {:ok, _pid} = CacheServer.start_link()
    Enum.each(1..10_000, fn i -> CacheServer.get(i))
  end
end
```

**Reference**: Freshcode.it benchmarks (ETS 5.22M vs GenServer 0.58M ops/sec)

---

## References

**Primary Sources**:
- Freshcode.it - "The Rails Developer's Guide to Mastering ETS in Elixir" (benchmark data)
- Hexdocs ETS documentation
- Elixir documentation on `:persistent_term`

**Related Patterns**:
- `genserver.md` - GenServer patterns
- `otp_supervisor.md` - Supervisor strategies
- `concurrent_tasks.md` - Task vs Agent vs GenServer
