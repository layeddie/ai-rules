# Concurrent Task Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: codesearch + web research (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Choosing between Task, Agent, and GenServer
- Building concurrent data pipelines
- Implementing back-pressure with GenStage/Broadway
- Creating worker pools for load balancing

❌ **DON'T use this file when**:
- Simple sequential operations (use Enum.map directly)
- One-off computations (use Task.async without strategy)
- Blocking operations that should use async
- High-contention scenarios without proper queuing

**See also**:
- `genserver.md` - GenServer patterns
- `otp_supervisor.md` - Supervisor strategies
- `ets_performance.md` - Performance decisions
- `error_handling.md` - Error handling in concurrent code

---

## Pattern 1: Task vs Agent vs GenServer Decision Matrix

**When to use each approach**:

| Scenario | Best Choice | Reason |
|-----------|-------------|---------|
| Fire-and-forget | Task.async | One-off, no state needed |
| Simple caching | Agent | Low overhead, simple API |
| Complex state | GenServer | State management, callbacks |
| Read-heavy caching | ETS | 2.14x faster than GenServer |
| High concurrency | GenStage | Back-pressure control |
| Data pipelines | Broadway | Production-proven pipelines |

✅ **Task Example**:
```elixir
defmodule OneOffWorker do
  def process(data) do
    result = expensive_computation(data)
    {:ok, result}
  end
end
```

✅ **Agent Example**:
```elixir
defmodule SimpleCache do
  def start_link do
    Agent.start_link(fn -> %{})
  end

  def get(key) do
    Agent.get(__MODULE__, fn map -> Map.get(map, key))
  end

  def put(key, value) do
    Agent.update(__MODULE__, fn map -> Map.put(map, key, value))
  end
end
```

---

## Pattern 2: GenStage for Back-Pressure

**Problem**: Producer overwhelms consumer

✅ **Solution**: Use Broadway with handle {:stop, :normal}

```elixir
defmodule DataProcessor do
  use Broadway

  def start_link do
    Broadway.start_link(__MODULE__)
  end

  def handle_message(message, context) do
    # Process message
    {:noreply, context}
  end

  def handle_batch(messages, batch_info, context) do
    case batch_info.batch_size do
      size when size > 100 ->
        # Producer too fast, signal back-pressure
        {:noreply, Broadway.Message.stop(context)}

      _ ->
        # Process normally
        messages
        |> Enum.map(&process_message/1)
        |> Enum.each(&send_downstream/1)
        {:noreply, context}
    end
  end

  def handle_batch(messages, _batch_info, context) do
    # All messages processed
    {:noreply, context}
  end
end
```

**Reference**: SoftwareMill - "Constructing effective data processing workflows using Elixir and Broadway" (2025)

---

## Pattern 3: Task.Supervisor for Pooling

**Problem**: Need multiple parallel workers

✅ **Solution**: Use Task.Supervisor for dynamic pools

```elixir
defmodule WorkerPool do
  def start_link do
    children = [
      {Task.Supervisor, name: MyWorkerPool},
      {MyApp.Worker, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  def add_work(worker_module, data) do
    Task.Supervisor.async(MyWorkerPool, worker_module, [data])
  end
end
```

**Reference**: Hexdocs Task.Supervisor (2025)

---

## Pattern 4: GenStage Consumer Groups

**Problem**: Multiple consumers need different processing

✅ **Solution**: Use consumer groups

```elixir
defmodule MyBroadway do
  use Broadway

  def start_link do
    producers = [
      default: [
        module: {MyApp.DataSource, [produce: :messages]}
      ]
    ]

    consumers = [
      group1: [
        module: {MyApp.Processor, []},
        concurrency: 5,
        min_demand: 10
      ],
      group2: [
        module: {MyApp.Validator, []},
        concurrency: 2,
        min_demand: 1
      ]
    ]

    Broadway.start_link(__MODULE__, opts)
  end
end
```

**Reference**: Broadway documentation

---

## Pattern 5: Rate Limiting with GenStage

**Problem**: Need to protect downstream services

✅ **Solution**: Use max_demand and sleep

```elixir
defmodule RateLimitedProducer do
  use GenStage

  def init do
    {:producer, state: 0}
  end

  def handle_demand(demand, _from, state) do
    {:noreply, min(demand, 10), state}
  end

  def handle_info(:sleep, state) do
    Process.sleep(100)
    {:noreply, state}
  end
end
```

---

## Pattern 6: Ordered Processing with GenStage

**Problem**: Messages must be processed in order

✅ **Solution**: Use ordered demand dispatcher

```elixir
defmodule OrderedProcessor do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, {dispers: 1})
  end

  def init do
    {:producer_consumer, state: %{queue: :queue.new(), demand: 0}}
  end

  def handle_subscribe(:consumer, _options, {from, _}) do
    {:consumer, from, from, subscribe_to: from}
  end

  def handle_events(events, _from, state) do
    events
    |> Enum.each(&Queue.enqueue/2)
    {:noreply, state, queue: state.queue}
  end
end
```

**Reference**: GenStage documentation

---

## Pattern 7: PartitionSupervisor for Load Distribution

**Problem**: Workers need to be distributed across cores

✅ **Solution**: Use PartitionSupervisor

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {PartitionSupervisor,
       child_spec: {MyApp.WorkerSup, []},
       max_children: System.schedulers_online()}
      }
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Reference**: codesearch "Elixir Task.Supervisor" (2025)

---

## Pattern 8: Timeout Handling in Concurrent Operations

**Problem**: Long-running tasks hang

✅ **Solution**: Use Task.await_with_timeout

```elixir
# Wrong: May hang
result = Task.await(long_task)

# Correct: With timeout
result = Task.await(long_task, 10_000)  # 10 seconds
```

**Reference**: Elixir documentation

---

## Pattern 9: Process Registry for Dynamic Supervision

**Problem**: Need to discover and manage dynamic children

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

  def lookup(worker_name, key) do
    case Registry.lookup(__MODULE__, worker_name, key) do
      [{^worker_name, pid}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def register(worker_name, pid) do
    Registry.register(__MODULE__, worker_name, pid)
  end
end
```

**Reference**: Hexdocs Registry documentation (2025)

---

## Testing Patterns for This File

### Unit Testing Task Patterns

```elixir
test "Task.async executes concurrently" do
  parent = self()

  tasks = Enum.map(1..10, fn _ ->
    Task.async(parent, fn ->
      Process.sleep(10)
      send(parent, :done)
    end)
  end)

  Enum.each(tasks, &Task.await/1)
  assert_received_messages([:done], 10)
end
```

### Integration Testing Broadway

```elixir
defmodule PipelineTest do
  use ExUnit.Case

  test "processes messages with back-pressure" do
    messages = Enum.to_list(1..1000)
    {:ok, processor} = start_supervised!(DataProcessor)

    Broadway.test_messages(processor, messages)

    assert_stop(processor)
  end
end
```

---

## References

**Primary Sources**:
- SoftwareMill - "Constructing effective data processing workflows using Elixir and Broadway" (2025)
- Quantum Fax Machine - "The secret weapon for processing millions of messages in order with Elixir" (2025)
- Hexdocs Broadway documentation

**Related Patterns**:
- `genserver.md` - GenServer patterns
- `otp_supervisor.md` - Supervisor strategies
- `ets_performance.md` - Performance considerations
