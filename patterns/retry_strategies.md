# Retry Strategies

**Purpose**: Exponential backoff and retry strategies for handling transient failures.

## Quick Start

```elixir
# Use retry library
defp deps do
  [
    {:retry, "~> 0.18"}
  ]
end

# Simple retry
{:ok, result} = Retry.retry_while(
  data,
  fn
    {:ok, result} = ExternalAPI.call(data)
    {:stop, {:ok, result}}
  end,
  should_retry?: &1
)
```

## Pattern 1: Exponential Backoff with Jitter

```elixir
defmodule MyApp.Retry do
  require Logger

  @default_max_attempts 3
  @default_base_delay 100
  @default_max_delay 10_000
  @default_jitter 0.1

  def with_retry(fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    base_delay = Keyword.get(opts, :base_delay, @default_base_delay)
    max_delay = Keyword.get(opts, :max_delay, @default_max_delay)
    jitter = Keyword.get(opts, :jitter, @default_jitter)

    do_retry(fun, max_attempts, base_delay, max_delay, jitter, 1)
  end

  defp do_retry(fun, max_attempts, base_delay, max_delay, jitter, attempt) do
    Logger.info("Retry attempt #{attempt}/#{max_attempts}")

    try do
      result = fun.()
      {:ok, result}
    rescue
      error ->
        Logger.error("Attempt #{attempt} failed: #{inspect(error)}")

        if attempt < max_attempts do
          delay = calculate_delay(base_delay, max_delay, attempt, jitter)
          Logger.info("Retrying in #{delay}ms...")
          :timer.sleep(delay)

          do_retry(fun, max_attempts, base_delay, max_delay, jitter, attempt + 1)
        else
          Logger.error("Max attempts (#{max_attempts}) reached")
          {:error, error}
        end
    end
  end

  defp calculate_delay(base_delay, max_delay, attempt, jitter) do
    exponential_delay = base_delay * :math.pow(2, attempt - 1) |> trunc()
    capped_delay = min(exponential_delay, max_delay)

    jitter_amount = trunc(capped_delay * jitter)
    random_jitter = :rand.uniform(jitter_amount)

    capped_delay + random_jitter
  end
end
```

## Pattern 2: Retry with Specific Errors

```elixir
defmodule MyApp.Retry.SpecificErrors do
  require Logger

  def with_retry(fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, 3)
    base_delay = Keyword.get(opts, :base_delay, 100)
    max_delay = Keyword.get(opts, :max_delay, 10_000)

    do_retry(fun, max_attempts, base_delay, max_delay, 1)
  end

  defp do_retry(fun, max_attempts, base_delay, max_delay, attempt) do
    Logger.info("Retry attempt #{attempt}/#{max_attempts}")

    try do
      result = fun.()
      {:ok, result}
    rescue
      error in [HTTPoison.Error, HTTPoison.AsyncError, Jason.DecodeError] ->
        Logger.error("Retryable error: #{inspect(error)}")

        if attempt < max_attempts do
          delay = calculate_delay(base_delay, max_delay, attempt)
          Logger.info("Retrying in #{delay}ms...")
          :timer.sleep(delay)

          do_retry(fun, max_attempts, base_delay, max_delay, attempt + 1)
        else
          Logger.error("Max attempts reached for retryable error")
          {:error, error}
        end

      error ->
        Logger.error("Non-retryable error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp calculate_delay(base_delay, max_delay, attempt) do
    exponential_delay = base_delay * :math.pow(2, attempt - 1) |> trunc()
    min(exponential_delay, max_delay)
  end
end
```

## Pattern 3: Retry with Circuit Breaker

```elixir
defmodule MyApp.Retry.WithCircuitBreaker do
  alias MyApp.Retry
  alias MyApp.CircuitBreaker

  def with_retry_and_circuit_breaker(service_name, fun, retry_opts \\ []) do
    Retry.with_retry(fun, retry_opts)
  end

  def with_retry_and_circuit_breaker(service_name, fun, retry_opts) do
    case CircuitBreaker.get_state(service_name) do
      :closed ->
        Logger.info("Circuit breaker closed, allowing request to #{service_name}")
        Retry.with_retry(fun, retry_opts)

      :open ->
        Logger.warning("Circuit breaker open for #{service_name}, skipping retry")
        {:error, :circuit_open}

      :half_open ->
        Logger.info("Circuit breaker half-open for #{service_name}, testing service")
        test_service(service_name, fun, retry_opts)
    end
  end

  defp test_service(service_name, fun, retry_opts) do
    try do
      result = fun.()
      {:ok, result}
    rescue
      error ->
        Logger.error("Service #{service_name} failed in half-open state")
        {:error, error}
    end
  end
end
```

## Pattern 4: Retry for Database Operations

```elixir
defmodule MyApp.DatabaseRetry do
  require Logger

  @transient_errors [
    Postgrex.Error,
    DBConnection.ConnectionError,
    DBConnection.ConnectionOwningError,
    DBConnection.Error
  ]

  def transaction_with_retry(repo, fun, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, 3)
    base_delay = Keyword.get(opts, :base_delay, 50)
    max_delay = Keyword.get(opts, :max_delay, 500)

    do_transaction(repo, fun, max_attempts, base_delay, max_delay, 1)
  end

  defp do_transaction(repo, fun, max_attempts, base_delay, max_delay, attempt) do
    Logger.info("Transaction attempt #{attempt}/#{max_attempts}")

    try do
      result = repo.transaction(fun)
      {:ok, result}
    rescue
      error when error in @transient_errors ->
        Logger.error("Transient database error: #{inspect(error)}")

        if attempt < max_attempts do
          delay = calculate_delay(base_delay, max_delay, attempt)
          Logger.info("Retrying transaction in #{delay}ms...")
          :timer.sleep(delay)

          do_transaction(repo, fun, max_attempts, base_delay, max_delay, attempt + 1)
        else
          Logger.error("Max transaction attempts reached")
          {:error, error}
        end

      error ->
        Logger.error("Non-transient database error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp calculate_delay(base_delay, max_delay, attempt) do
    exponential_delay = base_delay * :math.pow(2, attempt - 1) |> trunc()
    min(exponential_delay, max_delay)
  end
end
```

## Pattern 5: Retry with Backoff Library

```elixir
defp deps do
  [
    {:retry, "~> 0.18"}
  ]
end

defmodule MyApp.BackoffRetry do
  require Logger

  def with_backoff(fun, opts \\ []) do
    Retry.retry_while(
      opts,
      fn
        {:ok, result} = fun.()
        {:stop, {:ok, result}}
      end,
      retry_exp_backoff(100, 1_000),
      should_retry?: &1
    )
  end

  defp should_retry?({:error, error}) do
    is_transient_error?(error)
  end

  defp should_retry?(_), do: false

  defp is_transient_error?(error) do
    case error do
      %HTTPoison.Error{id: :closed} -> true
      %HTTPoison.Error{id: :timeout} -> true
      %Postgrex.Error{postgres: %{code: :connection_refused}} -> true
      _ -> false
    end
  end
end
```

## Best Practices

### DO

✅ Use exponential backoff for retries
✅ Add jitter to prevent thundering herd
✅ Limit maximum attempts
✅ Retry only transient errors
✅ Log all retry attempts
✅ Use circuit breaker for downstream services
✅ Make delays configurable
✅ Test retry logic with failing services
✅ Monitor retry success rates

### DON'T

❌ Retry infinite loops without limits
❌ Retry all errors (only transient)
❌ Hardcode delays (make configurable)
❌ Forget to log retry attempts
❌ Retry without backoff (can overwhelm services)
❌ Mix retry logic with business logic
❌ Retry client errors (4xx status codes)
❌ Ignore retry failures (track and alert)
❌ Skip jitter in distributed systems

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Design fault-tolerant systems
- **Orchestrator**: Implement retry strategies in features
- **DevOps Engineer**: Configure timeouts and thresholds
- **QA**: Test failure scenarios

### Skills to Reference

- **resilience-patterns**: This skill for comprehensive patterns
- **distributed-systems**: Combine with clustering strategies
- **observability**: Monitor retry patterns and failure rates

### Documentation Links

- **Circuit Breaker**: `patterns/circuit_breaker.md` (already created)
- **Bulkhead Patterns**: `patterns/bulkhead_patterns.md` (to create)
- **Graceful Degradation**: `patterns/graceful_degradation.md` (to create)

---

## Summary

Retry strategies provide:
- ✅ Exponential backoff for transient failures
- ✅ Jitter to prevent thundering herd
- ✅ Circuit breaker integration
- ✅ Configurable delays and attempts
- ✅ Transient error detection
- ✅ Database transaction retries

**Key**: Retry only transient errors, use exponential backoff with jitter, and integrate with circuit breakers.
