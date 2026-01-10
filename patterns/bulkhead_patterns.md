# Bulkhead Patterns

**Purpose**: Failure isolation patterns to prevent cascading failures.

## Quick Start

```elixir
# Task pool with bulkhead limit
{:ok, _pid} = MyApp.Bulkhead.start_link(pool_size: 10, queue_size: 100)

# Submit task with automatic timeout
{:ok, result} = MyApp.Bulkhead.submit_task(:my_pool, timeout: 5_000, fn ->
  ExternalAPI.process(data)
end)
```

## Pattern 1: Task Pool Limitation

```elixir
defmodule MyApp.Bulkhead do
  use GenServer
  require Logger

  @default_pool_size 10
  @default_queue_size 100

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  def submit_task(pool_name, fun, opts \\ []) do
    GenServer.cast(__MODULE__, {:submit_task, pool_name, fun, opts})
  end
  def get_pool_status(pool_name), do: GenServer.call(__MODULE__, {:get_status, pool_name})
  def shutdown_pool(pool_name), do: GenServer.cast(__MODULE__, {:shutdown, pool_name})

  # Server Callbacks
  @impl true
  def init(opts), do
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)
    queue_size = Keyword.get(opts, :queue_size, @default_queue_size)
    Logger.info("Starting bulkhead: pool_size: #{pool_size}, queue_size: #{queue_size}")

    {:ok, task_supervisor} = Task.Supervisor.start_link(__MODULE__, [], name: :task_supervisor)

    {:ok, %{
      task_supervisor: task_supervisor,
      pool_size: pool_size,
      queue_size: queue_size,
      pools: %{}
    }}
  end

  @impl true
  def handle_cast({:submit_task, pool_name, fun, opts}, state) do
    pool = Map.get(state.pools, pool_name)

    cond do
      nil ->
        # Pool not found
        Logger.error("Pool #{pool_name} not found")
        {:noreply, state}

      :shutdown ->
        # Pool is shutdown
        Logger.warning("Pool #{pool_name} is shutdown")
        {:noreply, state}

      true ->
        new_state = check_queue_and_submit(pool, fun, state)
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:shutdown, pool_name}, state) do
    Logger.info("Shutting down pool: #{pool_name}")
    new_state = update_in(state, [:pools, pool_name, :state], :shutdown)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get_status, pool_name}, _from, state) do
    pool = Map.get(state.pools, pool_name)
    status = if pool, do: get_pool_status(pool), else: :not_found)
    {:reply, status, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.info("Task completed, reason: #{inspect(reason)}")
    new_state = handle_task_completion(state)
    {:noreply, new_state}
  end

  # Implementation
  defp check_queue_and_submit(pool, fun, state) do
    cond do
      :queue.len(pool.queue) >= state.queue_size ->
        Logger.warning("Queue full for pool #{pool.name}, rejecting task")
        state

      pool.active_tasks >= state.pool_size ->
        Logger.warning("Pool full for #{pool.name}, queuing task")
        new_queue = :queue.in({pool.name, fun}, pool.queue)
        update_in(state, [:pools, pool.name], &%{&1 | queue: new_queue})
        state

      true ->
        # Start task
        task = Task.Supervisor.start_child(state.task_supervisor, fn ->
          fun.()
        end)
        new_pool = %{pool | active_tasks: pool.active_tasks + 1, tasks: [task | pool.tasks]}
        update_in(state, [:pools, pool.name], new_pool)
    end
  end

  defp handle_task_completion(state) do
    Enum.reduce(state.pools, state, fn {pool_name, pool}, acc ->
      new_pool = handle_pool_task_completion(pool)
      Map.put(acc, pool_name, new_pool)
    end)
  end

  defp handle_pool_task_completion(pool) do
    # Check which task completed
    {completed_tasks, remaining_tasks} = Enum.split_with(pool.tasks, fn task ->
      case Task.yield(task, 0) do
        {:ok, _} -> true
        {:error, _} -> false
        nil -> false
      end
    end)

    new_active_tasks = Enum.length(remaining_tasks)

    # Process queue
    {tasks_to_start, remaining_queue} = :queue.split(state.pool_size - new_active_tasks, pool.queue)

    Enum.each(tasks_to_start, fn {_pool_name, fun} ->
      Task.Supervisor.start_child(state.task_supervisor, fn ->
        fun.()
      end)
    end)

    %{pool |
      tasks: remaining_tasks,
      active_tasks: new_active_tasks,
      queue: remaining_queue
    }
  end

  defp get_pool_status(pool) do
    %{
      name: pool.name,
      active_tasks: pool.active_tasks,
      queued_tasks: :queue.len(pool.queue),
      pool_size: state.pool_size,
      queue_size: state.queue_size
    }
  end
end
```

## Pattern 2: Database Connection Pool

```elixir
defmodule MyApp.DatabasePool do
  use DBConnection.Pool
  require Logger

  def child_spec(opts) do
    opts = Keyword.merge([
      pool_size: 10,
      max_overflow: 5
    ], opts)

    DBConnection.Pool.child_spec(MyApp.Repo, opts)
  end

  def query(sql, params \\ [], opts \\ []) do
    DBConnection.Pool.query(MyApp.DatabasePool, sql, params, opts)
  end

  def transaction(fun, opts \\ []) do
    DBConnection.Pool.transaction(MyApp.DatabasePool, fun, opts)
  end
end
```

## Pattern 3: HTTP Client Pool

```elixir
defmodule MyApp.HTTPPool do
  use GenServer
  require Logger

  @default_pool_size 10
  @default_timeout 30_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def request(url, method, body, headers \\ []) do
    GenServer.call(__MODULE__, {:request, url, method, body, headers}, @default_timeout)
  end

  @impl true
  def init(opts), do
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)
    Logger.info("Starting HTTP pool with #{pool_size} connections")
    {:ok, %{available: pool_size, in_use: 0}}
  end

  @impl true
  def handle_call({:request, url, method, body, headers}, _from, state) do
    if state.in_use < state.available do
      # Make request
      result = make_http_request(url, method, body, headers)
      {:reply, {:ok, result}, %{state | in_use: state.in_use + 1}}
    else
      Logger.warning("HTTP pool exhausted, queuing request")
      # Queue request or return error
      {:reply, {:error, :pool_exhausted}, state}
    end
  end

  defp make_http_request(url, method, body, headers) do
    case HTTPoison.request(method, url, headers, body) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

## Pattern 4: Rate Limiter

```elixir
defmodule MyApp.RateLimiter do
  use GenServer
  require Logger

  @default_max_requests 100
  @default_window_ms 60_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def check_limit(client_id), do: GenServer.call(__MODULE__, {:check, client_id})
  def reset(client_id), do: GenServer.cast(__MODULE__, {:reset, client_id})

  @impl true
  def init(opts), do
    max_requests = Keyword.get(opts, :max_requests, @default_max_requests)
    window_ms = Keyword.get(opts, :window_ms, @default_window_ms)
    Logger.info("Starting rate limiter: #{max_requests} requests per #{window_ms}ms")

    {:ok, %{
      max_requests: max_requests,
      window_ms: window_ms,
      requests: %{},
      window_start: nil
    }}
  end

  @impl true
  def handle_call({:check, client_id}, _from, state) do
    now = System.monotonic_time(:millisecond)

    new_state = case get_in(state, [:requests, client_id]) do
      nil ->
        # First request for this client
        put_in(state, [:requests, client_id], [now])
        put_in(state, :window_start, now)
        {:ok, %{}, new_state}

      requests when is_list(requests) ->
        current_window = if state.window_start do
          elapsed = now - state.window_start

          if elapsed > state.window_ms do
            # New window
            new_requests = [now]
            new_window_start = now
            {:ok, %{}, put_in(state, [:requests, client_id], new_requests) | put_in(state, :window_start, new_window_start)}
          else
            if length(requests) < state.max_requests do
              # Request allowed
              new_requests = [now | requests]
              {:ok, %{}, put_in(state, [:requests, client_id], new_requests)}
            else
              # Rate limit exceeded
              {:error, :rate_limit_exceeded, state}
            end
        end

      _ ->
        {:error, :invalid_request_state, state}
    end

    {:reply, result, new_state}
  end

  @impl true
  def handle_cast({:reset, client_id}, state) do
    Logger.info("Resetting rate limit for client: #{client_id}")
    new_state = put_in(state, [:requests, client_id], [])
    {:noreply, new_state}
  end
end
```

## Pattern 5: Semaphore Pattern

```elixir
defmodule MyApp.Semaphore do
  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def acquire(timeout \\ 5_000), do: GenServer.call(__MODULE__, {:acquire, timeout}, timeout)
  def release, do: GenServer.cast(__MODULE__, :release)

  @impl true
  def init(opts), do
    permits = Keyword.get(opts, :permits, 5)
    Logger.info("Starting semaphore with #{permits} permits")

    {:ok, %{permits: permits, waiting: []}}
  end

  @impl true
  def handle_call({:acquire, timeout}, from, state) do
    cond do
      state.permits > 0 ->
        # Permit available
        new_state = %{state | permits: state.permits - 1}
        GenServer.reply(from, {:ok, :acquired})
        {:noreply, new_state}

      true ->
        # Wait for permit
        Logger.info("No permits available, queuing request")
        new_state = %{state | waiting: [from | state.waiting]}
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast(:release, state) do
    Logger.info("Releasing permit")

    case state.waiting do
      [next_requester | remaining_waiters] ->
        # Wake up waiting process
        GenServer.reply(next_requester, {:ok, :acquired})
        new_state = %{state | permits: state.permits + 1, waiting: remaining_waiters}
        {:noreply, new_state}

      [] ->
        new_state = %{state | permits: state.permits + 1}
        {:noreply, new_state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, _state) do
    # Handle crashed processes
    {:noreply, state}
  end
end
```

## Best Practices

### DO

✅ Use task pools to limit concurrent operations
✅ Use database connection pools (DBConnection.Pool)
✅ Use HTTP client pools for API requests
✅ Implement rate limiters to prevent overwhelming
✅ Use semaphores for resource management
✅ Set reasonable pool sizes and queue limits
✅ Monitor pool health and adjust sizes
✅ Handle pool exhaustion gracefully
✅ Use timeouts for all operations
✅ Log when requests are rejected due to bulkheads

### DON'T

❌ Use unbounded pools
❌ Set pool sizes too large (tune based on metrics)
❌ Forget to release resources (always use blocks/try)
❌ Ignore pool exhaustion errors
❌ Create single points of failure
❌ Forget to monitor pool performance
❌ Use blocking operations in pool workers
❌ Forget to configure timeouts for external calls

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Design fault-tolerant systems with bulkheads
- **Orchestrator**: Implement bulkhead patterns in features
- **DevOps Engineer**: Configure pool sizes and timeouts
- **Reviewer**: Verify bulkhead patterns prevent cascading failures

### Skills to Reference

- **resilience-patterns**: This skill for comprehensive patterns
- **distributed-systems**: Combine with clustering strategies
- **observability**: Monitor pool health and performance

### Documentation Links

- **Circuit Breaker**: `patterns/circuit_breaker.md` (already created)
- **Retry Strategies**: `patterns/retry_strategies.md` (already created)
- **Graceful Degradation**: `patterns/graceful_degradation.md` (to create)

---

## Summary

Bulkhead patterns provide:
- ✅ Task pool limitation
- ✅ Database connection pooling
- ✅ HTTP client pooling
- ✅ Rate limiting
- ✅ Semaphore pattern for resource management
- ✅ Failure isolation to prevent cascading failures

**Key**: Limit concurrent operations, use pools for resources, monitor health, and handle pool exhaustion gracefully.
