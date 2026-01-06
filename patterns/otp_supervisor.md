# OTP Supervisor Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: codesearch + Hexdocs OTP documentation (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Designing process supervision trees
- Managing application lifecycle
- Choosing supervisor strategies (one_for_one, one_for_all, rest_for_one)
- Creating dynamic supervisors
- Building fault-tolerant systems

❌ **DON'T use this file when**:
- Simple sequential tasks (use Task.async)
- Stateless operations (use functions/structs)
- One-off scripts (no process supervision needed)

**See also**:
- `genserver.md` - GenServer patterns
- `concurrent_tasks.md` - Task vs Agent vs GenServer
- `error_handling.md` - Error handling in supervisors

---

## Pattern 1: OneForOne Strategy for Independent Services

**Problem**: Need to restart only failed service

✅ **Solution**: Use `strategy: :one_for_one`

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {MyApp.Repo, []},
      {MyApp.Cache, []},
      {MyApp.Queue, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: Independent services that don't depend on each other (Database, Cache, Queue, etc.)

**Reference**: Hexdocs OTP documentation

---

## Pattern 2: OneForAll Strategy for Dependent Services

**Problem**: Multiple services must restart together or not at all

✅ **Solution**: Use `strategy: :one_for_all`

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Worker1, []},
      {DepWorker, [Worker1]}
    ]

    opts = [strategy: :one_for_all, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: Services that have dependencies (Worker depends on DepWorker)

**Reference**: codesearch "Elixir Supervisor strategies"

---

## Pattern 3: RestForOne for Service Pools

**Problem**: Multiple identical workers for load balancing

✅ **Solution**: Use `strategy: :rest_for_one`

```elixir
defmodule MyApp.WorkerSup do
  use Supervisor

  def start_link do
    children = [
      worker(Worker, [], id: 1),
      worker(Worker, [], id: 2),
      worker(Worker, [], id: 3)
    ]

    opts = [strategy: :rest_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: Identical workers that can be restarted individually or as a group

**Reference**: codesearch "Elixir Supervisor strategies"

---

## Pattern 4: DynamicSupervisor for Runtime Children

**Problem**: Need to add/remove children at runtime

✅ **Solution**: Use DynamicSupervisor

```elixir
defmodule MyApp.DynamicSup do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_worker(worker_module, opts) do
    spec = {worker_module, opts}
    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def remove_worker(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
```

**Reference**: Hexdocs Task.Supervisor documentation

---

## Pattern 5: Max Restart Frequency

**Problem**: Prevent infinite restart loops

✅ **Solution**: Set `max_restarts` and `max_seconds`

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {UnstableWorker, [max_restarts: 3, max_seconds: 5], []},
      {StableWorker, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: Workers that may fail but should not restart indefinitely

**Reference**: OTP documentation

---

## Pattern 6: PartitionSupervisor for Load Distribution

**Problem**: Distribute children across multiple cores

✅ **Solution**: Use PartitionSupervisor

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {PartitionSupervisor,
       child_spec: {MyApp.WorkerSup, []},
       max_children: System.schedulers_online(),
       name: MyApp.PartitionSupervisor}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: High-load applications with many parallel workers

**Reference**: codesearch "Elixir Supervisor strategies" + Arpit Shah (2025)

---

## Pattern 7: Supervisor Trees (Nested Supervisors)

**Problem**: Complex application needs hierarchical supervision

✅ **Solution**: Create supervisor tree

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {MyApp.TopSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.TopSupervisor do
  use Supervisor

  def start_link do
    children = [
      {MyApp.Repo, []},
      {MyApp.Cache, []},
      {MyApp.Workers, []}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.Workers do
  use Supervisor

  def start_link do
    children = [
      {Worker1, []},
      {Worker2, []},
      {Worker3, []}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: Complex applications requiring hierarchical organization

**Reference**: OTP documentation

---

## Pattern 8: Temporary Supervisors

**Problem**: Need to restart worker after initial setup completes

✅ **Solution**: Use `:temporary` option

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {SetupWorker, [restart: :temporary, shutdown: 1000]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**When to use**: One-time setup tasks that should complete and exit

**Reference**: OTP documentation

---

## Pattern 9: Global Process Registry

**Problem**: Need to lookup processes by name across the application

✅ **Solution**: Use Registry

```elixir
defmodule MyApp.Registry do
  use Registry

  def start_link do
    opts = [
      keys: :unique,
      name: __MODULE__,
      partitions: System.schedulers_online()
    ]
    Registry.start_link(opts)
  end

  def lookup(name) do
    case Registry.lookup(__MODULE__, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def register(name, pid) do
    Registry.register(__MODULE__, name, pid)
  end
end
```

**When to use**: Process discovery and messaging

**Reference**: Hexdocs Registry documentation

---

## Pattern 10: Supervisor for GenServer Testing

**Problem**: Need supervised environment for GenServer tests

✅ **Solution**: Use `start_supervised!` in tests

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
- Start/stop via supervision, not direct GenServer.start_link

**Reference**: `genserver.md` - GenServer Testing patterns

---

## Pattern 11: Backpressure Handling

**Problem**: Producer overwhelms consumer

✅ **Solution**: Use GenStage or handle {:stop, :normal}

```elixir
defmodule Consumer do
  use GenStage

  def handle_events(events, _from, state) do
    case events do
      [] when state.count >= 100 ->
        {:noreply, state}

      [event | rest] ->
        {:noreply, %{state | count: state.count + 1}}
    end
  end
end
```

**When to use**: Data pipelines where producer is faster than consumer

**Reference**: `concurrent_tasks.md` - Broadway/GenStage patterns

---

## Pattern 12: Error Handling in Supervisors

**Problem**: Child crashes should be handled gracefully

✅ **Solution**: Use Supervisor child_spec options

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {FragileWorker, [
        restart: :transient,
        shutdown: 5000,
        max_restarts: 5
      ]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Key Options**:
- `:permanent` - Always restart (default)
- `:temporary` - Never restart
- `:transient` - Restart only if abnormal termination
- `max_restarts` - Maximum restarts in time window
- `max_seconds` - Time window for restart counting

**Reference**: `error_handling.md` - Error handling patterns

---

## Testing Patterns for This File

### Unit Testing Supervisors

```elixir
test "supervisor starts children" do
  {:ok, pid} = start_supervised!(TestSupervisor, [])
  
  assert pid != nil
  stop_supervised(TestSupervisor)
end

### Integration Testing Restart Logic

```elixir
test "child restarts after crash" do
  {:ok, pid} = start_supervised!(UnstableWorker, restart: :transient})
  
  Process.exit(pid, :kill)
  :timer.sleep(100)
  
  assert {:ok, ^pid} = Supervisor.which_children(Supervisor)
end
```

---

## References

**Primary Sources**:
- Hexdocs OTP documentation
- codesearch "Elixir Supervisor strategies 2025"
- Arpit Shah (2025) - "Master Elixir GenServer: State Management & OTP Concurrency Guide"

**Related Patterns**:
- `genserver.md` - GenServer patterns
- `ets_performance.md` - Performance considerations
- `concurrent_tasks.md` - Task vs Agent vs GenServer
- `error_handling.md` - Error handling in processes
- `liveview.md` - LiveView patterns (if supervised state)
