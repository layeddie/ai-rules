# Performance Profiling Patterns

**Purpose**: Quick reference for performance profiling and optimization in Elixir/BEAM.

## Quick Start

```elixir
# Benchmark with Benchee
Benchee.run(%{
  "map" => fn -> Enum.map(1..1000, &(&1 * &1)) end,
  "reduce" => fn -> Enum.reduce(1..1000, 0, &(&1 + &1)) end
})

# Profile with :eprof
:eprof.start()
MyApp.Computation.intensive_function()
:eprof.stop()

# Profile with fprof
:fprof.trace(&MyApp.Computation.intensive_function/0)
```

## Benchmarking

### Benchee

```elixir
# Simple benchmark
Benchee.run(%{
  "map" => fn -> Enum.map(1..1000, &(&1 * &1)) end,
  "comprehension" => fn -> for n <- 1..1000, do: n * n end end,
  "Stream.map" => fn ->
    1..1000
    |> Stream.map(&(&1 * &1))
    |> Enum.to_list()
  end
})

# Comparison benchmark
Benchee.run(%{
  "map" => fn -> Enum.map(1..1000, &(&1 * &1)) end,
  "comprehension" => fn -> for n <- 1..1000, do: n * n end end
}, time: 2, memory_before: false)

# Memory profiling
Benchee.run(%{
  "list creation" => fn -> Enum.to_list(1..100_000) end,
  "binary creation" => fn -> :binary.copy(<<1>>, 100_000) end
end}, memory: 2)
```

### StreamData

```elixir
defmodule MyApp.Benchmarks do
  use ExUnit.Case
  require Logger
  use StreamData

  property "sort is transitive" do
    check all list(l1, l2, l3) do
      sort(l1, l2) == l2 and sort(l2, l3) == l1
    end
  end

  test "map preserves count" do
    check all list(list), do
      Enum.map(list, &(&1 + &1)) |> length() == length(list)
    end
  end

  test "reduce is associative" do
    check all integers(a, b, c), do
      a + (b + c) == (a + b) + c
    end
  end
end
```

## BEAM Profiling

### :eprof (Function Profiler)

```elixir
defmodule MyApp.Profiler do
  require Logger

  # Profile function
  def profile_function(module_name, function_name, args \\ []) do
    # Start profiler
    :eprof.start()

    # Run function
    apply(Module.concat([MyApp, module_name]), function_name, args)

    # Stop profiler
    :eprof.stop()

    # Analyze results
    display_results(:eprof.analyze())
  end

  defp display_results(results) do
    Logger.info("Profiling results:")
    Enum.each(results, fn {function, count, pct} ->
      Logger.info("  #{count}ms #{pct}% #{function}")
    end)
  end
end
```

### :fprof (System Profiler)

```elixir
defmodule MyApp.SystemProfiler do
  require Logger

  def profile_system(function, args \\ []) do
    # Start fprof
    :fprof.trace(&apply(function, args))

    # Get results
    results = :fprof.analyze()

    # Display results
    display_results(results)
  end

  defp display_results(results) do
    Logger.info("System profiling results:")
    Enum.each(results, fn {func, cnt, pct} ->
      Logger.info("  #{cnt}ms #{pct}% #{func}")
    end)
  end
end
```

### :eper (Advanced Profiler)

```elixir
# Mix task
defmodule Mix.Tasks.Profile.GenServer do
  use Mix.Task

  def run(_args) do
    # Start eper
    :eper.start()

    # Run GenServer operations
    MyApp.Worker.start_link()
    Enum.each(1..100, fn i ->
      MyApp.Worker.do_work(i)
    end)
    MyApp.Worker.stop()

    # Stop eper
    :eper.stop()

    # Get results
    results = :eprof.analyze()

    # Display results
    display_results(results)
  end

  defp display_results(results) do
    Mix.shell("eper results:")
    :eper.display(results)
  end
end
```

## Memory Profiling

### Erlang Memory

```elixir
defmodule MyApp.MemoryProfiler do
  require Logger

  def profile_function(function, args \\ []) do
    # Memory before
    memory_before = :erlang.memory(:total)

    # Run function
    result = apply(function, args)

    # Memory after
    memory_after = :erlang.memory(:total)

    # Calculate difference
    memory_diff = memory_after - memory_before

    Logger.info("Memory change: #{format_bytes(memory_diff)}")
    {result, memory_diff}
  end

  def format_bytes(bytes) do
    cond do
      bytes < 1_000 -> "#{bytes} B"
      bytes < 1_000_000 -> "#{div(bytes, 1_000)} KB"
      bytes < 1_000_000_000 -> "#{div(bytes, 1_000_000)} MB"
      true -> "#{div(bytes, 1_000_000_000)} GB"
    end
  end
end
```

### Memory Leak Detection

```elixir
defmodule MyApp.MemoryLeakDetector do
  use GenServer
  require Logger

  @check_interval 30_000 # 30 seconds

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get_stats(), do: GenServer.call(__MODULE__, :get_stats)

  @impl true
  def init(opts) do
    schedule_check()
    {:ok, %{
      memory_snapshots: %{},
      opts: opts
    }}
  end

  @impl true
  def handle_info(:check_memory, state) do
    take_snapshot()
    analyze_growth(state)
    schedule_check()
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, analyze_state(state), state}
  end

  defp schedule_check do
    Process.send_after(self(), :check_memory, @check_interval)
  end

  defp take_snapshot do
    memory = :erlang.memory(:total)
    timestamp = System.monotonic_time(:millisecond)
    GenServer.cast(__MODULE__, {:record_snapshot, memory, timestamp})
  end

  defp analyze_growth(state) do
    # Analyze memory growth patterns
    analyze_state(state)
    warn_on_high_growth(state)
  end

  defp analyze_state(state) do
    # Compare snapshots and detect leaks
    Enum.each(state.memory_snapshots, fn {_timestamp, snapshot} ->
      # Analyze memory patterns
      nil
    end)
  end

  defp warn_on_high_growth(state) do
    current_memory = :erlang.memory(:total)
    threshold = Application.get_env(:my_app, :memory_warning_threshold, 1_000_000_000) # 1GB

    if current_memory > threshold do
      Logger.error("High memory usage: #{format_bytes(current_memory)}")
    end
  end
end
```

## GenServer Optimization

### Non-Blocking Callbacks

```elixir
defmodule MyApp.OptimizedWorker do
  use GenServer
  require Logger

  # BAD: Blocking callback
  @impl true
  def handle_call(:heavy_operation, _from, state) do
    # Heavy operation blocks all other calls
    :timer.sleep(1000)
    {:reply, :done, state}
  end

  # GOOD: Non-blocking callback
  @impl true
  def handle_call(:heavy_operation, _from, state) do
    # Spawn task for heavy operation
    parent = self()
    Task.start(fn ->
      result = do_heavy_work()
      GenServer.reply(parent, {:ok, result})
    end)
    {:noreply, state}
  end

  defp do_heavy_work do
    :timer.sleep(1000)
    :done
  end
end
```

### Handle Overflow

```elixir
defmodule MyApp.QueueWorker do
  use GenServer
  require Logger

  @impl true
  def init(_opts) do
    {:ok, %{queue: :queue.new()}}
  end

  @impl true
  def handle_cast({:enqueue, item}, state) do
    new_queue = :queue.in(item, state.queue)

    if :queue.len(new_queue) > 10_000 do
      Logger.warning("Queue overflow, dropping oldest item")
      {_dropped, remaining_queue} = :queue.out(state.queue)
      {:noreply, %{state | queue: remaining_queue}}
    else
      {:noreply, %{state | queue: new_queue}}
    end
  end

  @impl true
  def handle_call({:dequeue, timeout}, from, state) do
    case :queue.out(state.queue) do
      {:value, item, new_queue} ->
        {:reply, item, %{state | queue: new_queue}}
      {:empty, _} ->
        {:reply, :empty, state}
      :timeout ->
        Logger.warning("Dequeue timeout")
        {:reply, :timeout, state}
    end
  end
end
```

### Process Batching

```elixir
defmodule MyApp.BatchProcessor do
  use GenServer
  require Logger

  @batch_size 100

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts), do: {:ok, %{batch: [], opts: opts}}

  @impl true
  def handle_cast({:process_batch, items}, state) do
    new_batch = state.batch ++ items

    if length(new_batch) >= @batch_size do
      process_batch(new_batch)
      {:noreply, %{state | batch: []}}
    else
      {:noreply, %{state | batch: new_batch}}
    end
  end

  defp process_batch(batch) do
    Logger.info("Processing batch of #{length(batch)} items")
    # Process batch
    Enum.each(batch, &MyApp.Processor.process_item/1)
    :timer.sleep(100) # Simulate processing time
  end
end
```

## Database Optimization

### N+1 Prevention

```elixir
# BAD: N+1 problem
def get_users_with_posts do
  users = Repo.all(User)
  Enum.map(users, fn user ->
    posts = Repo.all(from p in Post, where: p.user_id == ^user.id)
    %{user: user, posts: posts}
  end)
end

# GOOD: Preload associations
def get_users_with_posts do
  User
  |> Ash.Query.for_read()
  |> Ash.Query.load([:posts])
  |> Ash.read!()
end
```

### Query Optimization

```elixir
# Use indexes effectively
def get_active_users_by_date(date) do
  User
  |> Ash.Query.filter([active: true, created_at: after: ^date])
  |> Ash.Query.sort(created_at: :desc)
  |> Ash.Query.limit(100)
  |> Ash.read!()
end

# Use aggregation for statistics
def get_user_stats do
  User
  |> Ash.Query.aggregate([:count, :max_age], :first)
  |> Ash.Query.filter([active: true])
  |> Ash.read_one!()
end
```

## Hot Code Reloading

### Development Configuration

```elixir
# config/dev.exs
config :my_app,
  code_reloader: true,
  code_reloader_interval: 1000

# application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Start code reloader in development
      if Application.get_env(:my_app, :code_reloader, false) do
        {Phoenix.LiveReloader, {Phoenix.PubSub, [name: MyApp.PubSub]}}
      end,
      # Start application
      MyApp.Supervisor
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Production Considerations

```elixir
# Hot code reloading in production
# GOOD: Use releases
# BAD: Run mix commands in production
```

## Best Practices

### DO

✅ Benchmark before optimizing
✅ Use proper profilers for the task
✅ Profile memory usage and detect leaks
✅ Use non-blocking GenServer callbacks
✅ Process messages in batches
✅ Prevent N+1 queries with preloads
✅ Use hot code reloading only in development
✅ Monitor system metrics continuously
✅ Test optimizations with benchmarks
✅ Profile in production-like environments
✅ Use aggregation for statistics
✅ Optimize database queries with indexes

### DON'T

❌ Optimize without profiling data
❌ Use blocking operations in GenServer
❌ Ignore memory warnings
❌ Process one message at a time (batch when possible)
❌ Create N+1 queries in loops
❌ Hardcode hot code reload configuration
❌ Forget to commit optimization results
❌ Ignore database query plans
❌ Use system profiler for function profiling (use :eprof)
❌ Profile in development only (profile in production-like env)
❌ Forget to test after optimizing

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Design for performance
- **Orchestrator**: Implement optimizations
- **Reviewer**: Verify optimizations are correct
- **QA**: Benchmark and test improvements

### Skills to Reference

- **distributed-systems**: Cluster performance monitoring
- **resilience-patterns**: Graceful degradation for performance
- **observability**: Integrate performance metrics
- **test-generation**: Benchmark new features

---

## Summary

Performance profiling provides:
- ✅ Benchmarking tools (Benchee, StreamData)
- ✅ BEAM profilers (:eprof, :fprof, :eper)
- ✅ Memory profiling and leak detection
- ✅ GenServer optimization patterns
- ✅ Database query optimization
- ✅ Hot code reloading strategies

**Key**: Profile first, benchmark to verify improvements, and always test after optimization.
