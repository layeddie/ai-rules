# GenServer Patterns for Elixir Development

**Last Reviewed**: 2025-01-06  
**Source Material**: docs/genserver_guide.txt + docs/genserver_testing.txt + web research (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Building stateful processes with GenServer
- Implementing concurrent operations
- Designing process supervision trees
- Optimizing performance vs. simple structs

❌ **DON'T use this file when**:
- Simple stateless operations (use functions/structs)
- One-off scripts (use Task.async)
- Just need caching (use Agent or ETS)

**See also**:
- `otp_supervisor.md` - Supervisor strategies
- `ets_performance.md` - Performance decisions
- `concurrent_tasks.md` - Task vs Agent vs GenServer
- `error_handling.md` - Error handling in processes

---

## Pattern 1: Non-blocking GenServer Callbacks

**Problem**: Blocking `handle_call`/`handle_cast` can starve schedulers

❌ **Anti-pattern**:
```elixir
defmodule BlockingServer do
  use GenServer

  def handle_call(:slow_operation, _from, state) do
    :timer.sleep(5000)  # ❌ Blocks for 5 seconds
    {:reply, :done, state}
  end
end
```

✅ **Solution**: Use `handle_info` with async operations
```elixir
defmodule NonBlockingServer do
  use GenServer

  def handle_call(:start_slow_operation, from, state) do
    Task.start(fn ->
      result = slow_operation()
      GenServer.cast(from, {:operation_complete, result})
    end)
    {:reply, :started, state}
  end

  def handle_cast({:operation_complete, result}, state) do
    {:noreply, Map.put(state, :result, result)}
  end
end
```

**Performance Impact**: 
- Non-blocking: 5.22 M ops/sec (ETS table benchmark)
- Blocking: 0.58 M ops/sec (8.95x slower)

**Reference**: `docs/genserver_guide.txt` (Freshcode.it benchmarks)

---

## Pattern 2: ETS vs GenServer for Read-Heavy Workloads

**Decision Matrix**:

| Use Case | Recommendation | Reason |
|-----------|----------------|---------|
| High read, low write | ETS table | 2.14x faster than GenServer |
| Read + write in one op | GenServer with Agent | Maintains transaction safety |
| Complex state logic | GenServer | Easier to reason about behavior |
| Simple caching | Agent or `:persistent_term` | Minimal overhead |

✅ **ETS Example**:
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

**Reference**: Benchmark from Freshcode.it - ETS 5.22M ops/sec vs GenServer 0.58M ops/sec

---

## Pattern 3: Supervisor Restart Strategies

**Strategy Selection Guide**:

| Strategy | Use Case | Example |
|----------|-----------|---------|
| `:one_for_one` | Independent services (Database, Cache) | `Supervisor.start_link([Repo, Cache], strategy: :one_for_one)` |
| `:one_for_all` | Dependent services (must restart together) | `Supervisor.start_link([Worker, DepWorker], strategy: :one_for_all)` |
| `:rest_for_one` | Service pools (identical workers) | `Supervisor.start_link([worker(Server, [], id: 1), worker(Server, [], id: 2)], strategy: :rest_for_one)` |

✅ **Dynamic Supervisor Example**:
```elixir
defmodule DynamicWorkerSup do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_worker(worker_module, opts) do
    spec = {worker_module, opts}
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
```

**Reference**: Hexdocs OTP documentation + codesearch Supervisor patterns

---

## Pattern 4: GenServer Testing with Isolation

**Problem**: Testing GenServers often requires starting processes in test environment

✅ **Test Pattern**:
```elixir
defmodule CounterServerTest do
  use ExUnit.Case, async: false  # Important: Don't use async

  setup do
    {:ok, pid} = start_supervised!(CounterServer, 0)
    %{pid: pid}
  end

  test "increments counter", %{assigns: %{pid: pid}} do
    assert CounterServer.value(pid) == 0
    CounterServer.increment(pid)
    assert CounterServer.value(pid) == 1
  end
end
```

**Key Principles**:
- Use `async: false` for GenServer tests
- Start/stop via supervision, not direct `GenServer.start_link`
- Test state transitions, not just API surface

**Reference**: `docs/genserver_testing.txt` (Freshcode.it guide)

---

## Pattern 5: Instrument Before Optimizing

**Performance Checklist**:

- [ ] Profile with `:fprof` before optimizing
- [ ] Use `:observer.start()` for runtime inspection
- [ ] Check scheduler balance: `:erlang.system_info(:scheduler_wall_time)`
- [ ] Identify hot paths with `:eper` (Erlang profiler)

✅ **Optimization Pattern**:
```elixir
defmodule OptimizedServer do
  use GenServer

  def handle_call(:expensive_op, _from, state) do
    result = optimized_computation(state.cache)
    {:reply, result, state}
  end
end
```

**Reference**: Freshcode.it - "Instrument first, optimise second"

---

## Pattern 6: Non-blocking Callbacks with Task.async

**Problem**: CPU-intensive operations in callbacks

✅ **Pattern**:
```elixir
defmodule AsyncWorkerServer do
  use GenServer

  def handle_call(:process_data, _from, state) do
    Task.start(fn ->
      result = cpu_intensive_work()
      GenServer.reply(from, {:result, result})
    end)
    {:reply, :processing, state)}
  end
end
```

---

## Pattern 7: State Management Best Practices

**Guidelines**:
- Minimize state size
- Use maps for quick lookups
- Leverage `:persistent_term` for read-only shared state
- Externalize heavy state to ETS

✅ **Pattern**:
```elixir
defmodule StatefulServer do
  use GenServer

  def init do
    {:ok, %{
      users: :ets.new(:users, [:set, :protected]),
      metrics: :ets.new(:metrics, [:bag]),
      cache: Map.new()
    }}
  end

  def get_user(user_id) do
    case :ets.lookup(:users, user_id) do
      [{^user_id, user}] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end
end
```

**Reference**: `ets_performance.md` for ETS patterns

---

## Pattern 8: Handle_info vs Cast for Async Work

**Decision Guide**:

| Scenario | Best Choice | Reason |
|----------|-------------|---------|
| One-way updates | `handle_info` | Simpler, no reply needed |
| Request-response | `handle_call` | Synchronous, caller waits |
| Fire-and-forget | `handle_cast` | Asynchronous, no response |

✅ **Pattern**:
```elixir
defmodule AsyncProcessor do
  use GenServer

  def start_processing(task_data) do
    GenServer.cast(__MODULE__, {:process_task, task_data})
  end

  def handle_cast({:process_task, data}, state) do
    Task.start(fn ->
      result = process(data)
      GenServer.cast(__MODULE__, {:task_complete, result})
    end)
    {:noreply, state}
  end
end
```

**Reference**: `concurrent_tasks.md` for Task vs Agent vs GenServer

---

## Pattern 9: Timeout Handling in GenServers

**Problem**: Long-running operations can timeout

✅ **Pattern**:
```elixir
defmodule TimeoutAwareServer do
  use GenServer

  def handle_call(:long_operation, from, state) do
    Task.start(fn ->
      result = long_operation()
      GenServer.reply(from, result, 5000)  # 5 second timeout
    end)
    {:noreply, state}
  end
end
```

---

## Pattern 10: GenServer Call Tracing

**Purpose**: Debug GenServer call flow

✅ **Pattern**:
```elixir
defmodule TracedServer do
  use GenServer

  def handle_call(op, from, state) do
    Logger.debug("GenServer call: #{inspect(op)} from #{inspect(from)}")
    result = process(op, state)
    {:reply, result, state}
  end
end
```

**Reference**: `docs/genserver_guide.txt` (observability patterns)

---

## Testing Patterns for This File

### Unit Testing
```elixir
test "increment increments value" do
  {:ok, pid} = start_supervised!(CounterServer, 0)
  assert CounterServer.value(pid) == 0
  CounterServer.increment(pid)
  assert CounterServer.value(pid) == 1
  stop_supervised(CounterServer)
end
```

### Integration Testing
```elixir
test "process handles concurrent requests" do
  {:ok, pid} = start_supervised!(CounterServer, 0)
  tasks = Enum.map(1..10, fn _ -> Task.async(CounterServer.increment(pid)) end)
  Enum.each(tasks, &Task.await/1)
  assert CounterServer.value(pid) == 10
  stop_supervised(CounterServer)
end
```

---

## References

**Primary Sources**:
- `docs/genserver_guide.txt` - Freshcode.it real-world guide (11,500 chars)
- `docs/genserver_testing.txt` - Testing strategies (11,216 chars)
- Ihor Katkov (2025) - "You Built a GenServer. Now Make It Fast, Observable, and Bulletproof"
- Jonny Eberhardt (2025) - "Break It Before It Breaks You: Advanced Testing Strategies"
- Arpit Shah (2025) - "Master Elixir GenServer: State Management & OTP Concurrency Guide"

**Related Patterns**:
- `otp_supervisor.md` - Supervisor strategies
- `ets_performance.md` - ETS vs GenServer decisions
- `concurrent_tasks.md` - Task vs Agent vs GenServer
- `error_handling.md` - Error handling in processes

**Deep Dives**:
- `skills/otp-patterns/SKILL.md` - Comprehensive OTP guide
- `skills/liveview-patterns/SKILL.md` - LiveView (if GenServer used for state)

**Community**:
- Elixir Forum: "How to design and test Elixir GenServers"
- Freshcode.it blog series on Elixir performance
