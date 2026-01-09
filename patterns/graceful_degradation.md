# Graceful Degradation

**Purpose**: Graceful degradation strategies for partial system failures.

## Quick Start

```elixir
# Check feature flag before calling service
if FeatureFlags.is_enabled?(:advanced_search) do
  AdvancedAPI.search(query)
else
  BasicAPI.search(query)
end
```

## Pattern 1: Feature Flags

```elixir
defmodule MyApp.FeatureFlags do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  def is_enabled?(feature_name), do: GenServer.call(__MODULE__, {:is_enabled, feature_name})
  def enable(feature_name), do: GenServer.cast(__MODULE__, {:enable, feature_name})
  def disable(feature_name), do: GenServer.cast(__MODULE__, {:disable, feature_name})
  def get_all_flags(), do: GenServer.call(__MODULE__, :get_all)

  # Server Callbacks
  @impl true
  def init(opts), do
    Logger.info("Starting feature flags")
    features = Application.get_env(:my_app, :features, %{})
    {:ok, features}
  end

  @impl true
  def handle_call({:is_enabled, feature_name}, _from, state) do
    enabled = Map.get(state, feature_name, false)
    Logger.info("Feature #{feature_name} enabled: #{enabled}")
    {:reply, enabled, state}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:enable, feature_name}, state) do
    Logger.info("Enabling feature: #{feature_name}")
    {:noreply, Map.put(state, feature_name, true)}
  end

  @impl true
  def handle_cast({:disable, feature_name}, state) do
    Logger.warning("Disabling feature: #{feature_name}")
    {:noreply, Map.put(state, feature_name, false)}
  end
end

# Use in application
defmodule MyApp.UserController do
  alias MyApp.FeatureFlags

  def index(conn, _params) do
    # Check if advanced search is enabled
    if FeatureFlags.is_enabled?(:advanced_search) do
      render_advanced_search(conn)
    else
      render_basic_search(conn)
    end
  end
end
```

## Pattern 2: Fallback Services

```elixir
defmodule MyApp.UserService do
  alias MyApp.FeatureFlags
  require Logger

  def get_user_profile(user_id) do
    case FeatureFlags.is_enabled?(:external_user_service) do
      true ->
        Logger.info("Using external user service")
        get_user_profile_external(user_id)
      false ->
        Logger.info("Using local user service (fallback)")
        get_user_profile_local(user_id)
    end
  end

  defp get_user_profile_external(user_id) do
    case ExternalAPI.get_user(user_id) do
      {:ok, user} -> {:ok, user}
      {:error, _reason} ->
        Logger.warning("External service failed, using fallback")
        get_user_profile_local(user_id)
    end
  end

  defp get_user_profile_local(user_id) do
    # Fallback: fetch from local database
    case MyApp.Repo.get(MyApp.User, user_id) do
      user when not is_nil(user) -> {:ok, user}
      nil -> {:error, :not_found}
    end
  end
end
```

## Pattern 3: Caching with Degradation

```elixir
defmodule MyApp.CachedService do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get_data(key, opts \\ []), do: GenServer.call(__MODULE__, {:get_data, key, opts})
  def invalidate_cache(key), do: GenServer.cast(__MODULE__, {:invalidate, key})

  # Server Callbacks
  @impl true
  def init(opts), do
    cache_ttl = Keyword.get(opts, :cache_ttl, 3_600_000)
    Logger.info("Starting cached service with TTL: #{cache_ttl}ms")
    {:ok, %{cache: %{}, cache_ttl: cache_ttl}}
  end

  @impl true
  def handle_call({:get_data, key, opts}, _from, state) do
    case Map.get(state.cache, key) do
      {data, timestamp} ->
        if expired?(timestamp, state.cache_ttl) do
          Logger.info("Cache expired for key: #{key}")
          fetch_and_cache(key, state)
        else
          Logger.info("Cache hit for key: #{key}")
          {:reply, {:ok, data}, state}
        end

      nil ->
        Logger.info("Cache miss for key: #{key}")
        fetch_and_cache(key, state)
    end
  end

  @impl true
  def handle_cast({:invalidate, key}, state) do
    Logger.info("Invalidating cache for key: #{key}")
    new_cache = Map.delete(state.cache, key)
    {:noreply, %{state | cache: new_cache}}
  end

  defp fetch_and_cache(key, state) do
    case fetch_from_source(key) do
      {:ok, data} ->
        new_cache = Map.put(state.cache, key, {data, System.monotonic_time(:millisecond)})
        new_state = %{state | cache: new_cache}
        {:reply, {:ok, data}, new_state}
      {:error, reason} ->
        Logger.error("Failed to fetch data: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  defp fetch_from_source(key) do
    case MyApp.FeatureFlags.is_enabled?(:external_api) do
      true ->
        ExternalAPI.get_data(key)
      false ->
        LocalAPI.get_data(key)
    end
  end

  defp expired?(timestamp, ttl) do
    current_time = System.monotonic_time(:millisecond)
    current_time - timestamp > ttl
  end
end
```

## Pattern 4: Progressive Degradation

```elixir
defmodule MyApp.ProgressiveDegradation do
  use GenServer
  require Logger

  @degration_levels [:full, :degraded, :minimal, :offline]

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def get_current_level(), do: GenServer.call(__MODULE__, :get_level)
  def report_failure(service_name), do: GenServer.cast(__MODULE__, {:report_failure, service_name})
  def report_recovery(service_name), do: GenServer.cast(__MODULE__, {:report_recovery, service_name})

  # Server Callbacks
  @impl true
  def init(opts), do
    Logger.info("Starting progressive degradation")
    {:ok, %{
      current_level: :full,
      service_health: %{},
      failures: %{},
      recovery_count: 0,
      opts: opts
    }}
  end

  @impl true
  def handle_call(:get_level, _from, state) do
    Logger.info("Current degradation level: #{state.current_level}")
    {:reply, state.current_level, state}
  end

  @impl true
  def handle_cast({:report_failure, service_name}, state) do
    new_state = handle_failure(service_name, state)
    Logger.warning("Service #{service_name} failed, new level: #{new_state.current_level}")
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:report_recovery, service_name}, state) do
    Logger.info("Service #{service_name} recovered")
    new_state = handle_recovery(service_name, state)
    {:noreply, new_state}
  end

  defp handle_failure(service_name, state) do
    # Update service health
    new_health = Map.update(state.service_health, service_name, fn
      %{failures: failures, last_failure: nil} ->
        %{failures: failures + 1, last_failure: DateTime.utc_now()}
      current_health ->
        current_health
    end)
    end)

    # Check if we need to degrade
    new_level = calculate_degradation_level(new_health, state)

    %{state |
      service_health: new_health,
      current_level: new_level
    }
  end

  defp handle_recovery(service_name, state) do
    # Reset service health on recovery
    new_health = Map.update(state.service_health, service_name, fn
      _current_health ->
        %{failures: 0, last_failure: nil}
    end)
    end)

    # Recalculate level
    new_level = calculate_degradation_level(new_health, state)

    %{state |
      service_health: new_health,
      current_level: new_level,
      recovery_count: state.recovery_count + 1
    }
  end

  defp calculate_degradation_level(health, state) do
    failed_services = Enum.filter(health, fn {_service, status} ->
      status.failures >= state.opts.failure_threshold
    end)

    failed_count = length(failed_services)

    cond do
      failed_count == 0 -> :full
      failed_count <= 1 -> :degraded
      failed_count <= 2 -> :minimal
      true -> :offline
    end
  end
end
```

## Pattern 5: Load Shedding

```elixir
defmodule MyApp.LoadShedder do
  use GenServer
  require Logger

  # Client API
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def should_accept_request?(), do: GenServer.call(__MODULE__, :should_accept)
  def report_request_start(), do: GenServer.cast(__MODULE__, :report_request_start)
  def report_request_end(duration), do: GenServer.cast(__MODULE__, {:report_request_end, duration})

  # Server Callbacks
  @impl true
  def init(opts), do
    max_qps = Keyword.get(opts, :max_qps, 1000)
    window_ms = Keyword.get(opts, :window_ms, 1_000)
    Logger.info("Starting load shedder: max_qps: #{max_qps}, window: #{window_ms}ms")
    {:ok, %{
      max_qps: max_qps,
      window_ms: window_ms,
      requests: [],
      window_start: nil,
      current_qps: 0
    }}
  end

  @impl true
  def handle_call(:should_accept, _from, state) do
    should_accept = state.current_qps < state.max_qps
    {:reply, should_accept, state}
  end

  @impl true
  def handle_cast(:report_request_start, state) do
    now = System.monotonic_time(:millisecond)
    new_state = cleanup_old_requests(state, now)

    new_requests = [{:start, now} | new_state.requests]
    current_qps = calculate_current_qps(new_requests, new_state.window_start, new_state.window_ms)
    new_window_start = if length(new_requests) == 1, do: now, else: new_state.window_start

    {:noreply, %{new_state |
      requests: new_requests,
      window_start: new_window_start,
      current_qps: current_qps
    }}
  end

  @impl true
  def handle_cast({:report_request_end, duration}, state) do
    now = System.monotonic_time(:millisecond)

    new_requests = Enum.map(state.requests, fn
      :start, start_time} ->
        if now >= start_time + duration do
          {:complete, start_time, duration}
        else
          {:in_progress, start_time}
        end
    end)

    new_state = %{state | requests: new_requests}
    {:noreply, new_state}
  end

  defp cleanup_old_requests(state, now) do
    cutoff = now - state.window_ms

    Enum.filter(state.requests, fn
      :start, start_time} ->
        start_time >= cutoff
      :complete ->
        true
      :in_progress ->
        true
    end)
  end

  defp calculate_current_qps(requests, window_start, window_ms) do
    now = System.monotonic_time(:millisecond)
    window_requests = Enum.filter(requests, fn
      {:complete, start_time, _} ->
        start_time >= now - window_ms && start_time >= window_start
      _ ->
        false
    end)

    length(window_requests)
  end
end
```

## Best Practices

### DO

✅ Start with feature flags
✅ Use fallback services for external dependencies
✅ Implement caching with TTL
✅ Progressive degradation levels
✅ Load shedding for rate limiting
✅ Log all degradation events
✅ Monitor degradation triggers
✅ Test failure scenarios
✅ Automatic recovery

### DON'T

❌ Fail completely (provide fallback)
❌ Hardcode degradation levels (make configurable)
❌ Forget to restore services on recovery
❌ Ignore cascade failures
❌ Forget to monitor system health
❌ Use synchronous calls in fallback paths
❌ Forget to log degradation events

---

## Integration with ai-rules

### Roles to Reference

- **Architect**: Design fault-tolerant systems
- **Orchestrator**: Implement graceful degradation in features
- **DevOps Engineer**: Configure monitoring and alerts
- **QA**: Test failure scenarios and degradation paths

### Skills to Reference

- **distributed-systems**: Combine with clustering strategies
- **resilience-patterns**: This skill for comprehensive resilience
- **observability**: Monitor degradation events and system health

### Documentation Links

- **Circuit Breaker**: `patterns/circuit_breaker.md` (already created)
- **Retry Strategies**: `patterns/retry_strategies.md` (already created)
- **Bulkhead Patterns**: `patterns/bulkhead_patterns.md` (already created)

---

## Summary

Graceful degradation provides:
- ✅ Feature flags for controlled rollout
- ✅ Fallback services for external dependencies
- ✅ Caching with TTL for resilience
- ✅ Progressive degradation levels
- ✅ Load shedding for rate limiting
- ✅ Automatic recovery monitoring
- ✅ System health tracking

**Key**: Design for partial failures, provide fallbacks, and implement automatic recovery.
