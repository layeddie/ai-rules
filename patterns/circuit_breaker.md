# Circuit Breaker Pattern

**Purpose**: Circuit breaker implementation for failure isolation.

## Quick Start

```elixir
# Use circuit breaker GenServer
{:ok, result} = MyApp.CircuitBreaker.call(:external_service, fn ->
  ExternalAPI.process(data)
end)
```

## Pattern: State Machine

```elixir
defmodule MyApp.CircuitBreaker do
  use GenServer
  require Logger

  @states [:closed, :open, :half_open]
  @default_threshold 5
  @default_timeout 60_000
  @default_retry_timeout 10_000

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))

  def call(service_name, fun, opts \\ []) do
    GenServer.call(__MODULE__, {:call, service_name, fun, opts})
  end

  def get_state(service_name) do
    GenServer.call(__MODULE__, {:get_state, service_name})
  end

  def reset(service_name) do
    GenServer.cast(__MODULE__, {:reset, service_name})
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    Logger.info("Starting circuit breaker")
    {:ok, %{
      services: %{},
      opts: opts
    }}
  end

  @impl true
  def handle_call({:call, service_name, fun, opts}, from, state) do
    service_state = Map.get(state.services, service_name, default_state())

    case service_state.state do
      :closed ->
        result = execute_and_track(service_name, fun, service_state)
        {:reply, result, update_service(state, service_name, service_state)}

      :open ->
        Logger.warning("Circuit breaker OPEN for #{service_name}")
        {:reply, {:error, :circuit_open}, update_service(state, service_name, service_state)}

      :half_open ->
        Logger.info("Circuit breaker HALF-OPEN for #{service_name}, testing service")
        result = test_service(service_name, fun, service_state)
        {:reply, result, update_after_test(service_name, result, service_state)}
    end
  end

  @impl true
  def handle_cast({:reset, service_name}, state) do
    Logger.info("Resetting circuit breaker for #{service_name}")
    {:noreply, reset_service(state, service_name)}
  end

  @impl true
  def handle_info({:reset_circuit, service_name}, state) do
    Logger.info("Circuit breaker reset for #{service_name}")
    {:noreply, reset_service(state, service_name)}
  end

  # Implementation
  defp default_state do
    %{
      state: :closed,
      failures: 0,
      threshold: Application.get_env(:my_app, :circuit_breaker_threshold, @default_threshold),
      timeout: Application.get_env(:my_app, :circuit_breaker_timeout, @default_timeout),
      retry_timeout: Application.get_env(:my_app, :circuit_breaker_retry_timeout, @default_retry_timeout),
      last_failure_time: nil
    }
  end

  defp execute_and_track(service_name, fun, service_state) do
    try do
      result = fun.()
      # Success: reset failures
      {:ok, result}
    rescue
      error ->
        Logger.error("Service #{service_name} failed: #{inspect(error)}")
        # Increment failures and check threshold
        failures = service_state.failures + 1
        threshold = service_state.threshold

        if failures >= threshold do
          Logger.warning("Circuit breaker opening for #{service_name} after #{failures} failures")
          timeout = service_state.timeout
          # Schedule reset
          Process.send_after(self(), {:reset_circuit, service_name}, timeout)

          %{service_state |
            state: :open,
            failures: failures,
            last_failure_time: DateTime.utc_now()
          }
        else
          %{service_state |
            failures: failures
          }
        end

        {:error, error}
    end
  end

  defp test_service(service_name, fun, service_state) do
    retry_timeout = service_state.retry_timeout

    try do
      result = fun.()
      # Success: close circuit
      {:ok, result}
    rescue
      error ->
        Logger.error("Service #{service_name} failed in half-open state")
        # Failure: open circuit
        timeout = service_state.timeout
        Process.send_after(self(), {:reset_circuit, service_name}, timeout)

        {:error, error}
    end
  end

  defp update_after_test(service_name, {:ok, _result}, service_state) do
    # Success in half-open: close circuit
    reset_state(service_state)
  end

  defp update_after_test(service_name, {:error, _reason}, service_state) do
    # Failure in half-open: open circuit
    timeout = service_state.timeout
    Process.send_after(self(), {:reset_circuit, service_name}, timeout)

    %{service_state |
      state: :open,
      failures: service_state.failures + 1,
      last_failure_time: DateTime.utc_now()
    }
  end

  defp update_service(state, service_name, service_state) do
    put_in(state, [:services, service_name], service_state)
  end

  defp reset_service(state, service_name) do
    reset_state = default_state()
    put_in(state, [:services, service_name], reset_state)
  end

  defp reset_state(service_state) do
    %{service_state |
      state: :closed,
      failures: 0,
      last_failure_time: nil
    }
  end
end
```

## Usage Example

```elixir
# In application
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {MyApp.CircuitBreaker, [
        name: MyApp.CircuitBreaker
      ]}
    ]
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# In feature
defmodule MyApp.UserService do
  alias MyApp.CircuitBreaker

  def get_user(id) do
    case CircuitBreaker.call(:user_api, fn ->
      ExternalAPI.get_user(id)
    end) do
      {:ok, user} -> {:ok, user}
      {:error, :circuit_open} -> {:error, :service_unavailable}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

## Best Practices

### DO

✅ **Start in closed state**: Circuit starts allowing requests
✅ **Track failures**: Count consecutive failures
✅ **Use configurable thresholds**: Adjust based on service reliability
✅ **Implement timeout**: Schedule automatic reset
✅ **Log state changes**: Track circuit open/close
✅ **Test half-open**: Probe service before fully opening

### DON'T

❌ **Hardcode thresholds**: Make configurable per service
❌ **Ignore half-open state**: Always test before fully reopening
❌ **Forget to reset**: Circuit stays open forever
❌ **Mix concerns**: Keep circuit logic separate from business logic
❌ **Use infinite timeout**: Always set reasonable reset timeout
❌ **Log sensitive data**: Don't log user data in circuit failures

---

## Integration with ai-rules

### Skills to Reference

- **distributed-systems**: Combine with clustering strategies
- **resilience-patterns**: This skill for comprehensive resilience
- **observability**: Monitor circuit states and failure patterns

### Roles to Reference

- **Architect**: Design fault-tolerant systems
- **Orchestrator**: Implement circuit breakers in features
- **Reviewer**: Verify resilience patterns are properly implemented

---

## Summary

Circuit breaker pattern provides:
- ✅ Failure isolation
- ✅ Automatic recovery
- ✅ Configurable thresholds
- ✅ Timeout handling
- ✅ State tracking

**Key**: Start closed, track failures, open on threshold, reset on timeout.
