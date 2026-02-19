# Prometheus Integration Example

## Complete Prometheus Setup for Elixir/Phoenix

### Dependencies

```elixir
# mix.exs
def deps do
  [
    {:prometheus, "~> 4.6"},
    {:prometheus_plugs, "~> 1.1"},
    {:prometheus_phoenix, "~> 1.3"},
    {:prometheus_ecto, "~> 1.4"},
    {:prometheus_process_collector, "~> 1.3"}
  ]
end
```

### Prometheus Configuration

```elixir
# lib/my_app/prometheus.ex
defmodule MyApp.Prometheus do
  use Prometheus

  def setup do
    # Setup default collectors
    Prometheus.Registry.setup()
    
    # Setup custom metrics
    setup_metrics()
    
    # Setup exporters
    Prometheus.Exporter.setup()
  end

  defp setup_metrics do
    # Counter: HTTP requests
    Prometheus.Counter.new(
      name: :http_requests_total,
      help: "Total number of HTTP requests",
      labels: [:method, :path, :status]
    )

    # Histogram: Request duration
    Prometheus.Histogram.new(
      name: :http_request_duration_seconds,
      help: "HTTP request duration in seconds",
      labels: [:method, :path],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
    )

    # Gauge: Active connections
    Prometheus.Gauge.new(
      name: :active_connections,
      help: "Number of active connections",
      labels: [:type]
    )

    # Counter: Business metrics
    Prometheus.Counter.new(
      name: :users_created_total,
      help: "Total number of users created",
      labels: [:source]
    )

    Prometheus.Counter.new(
      name: :orders_total,
      help: "Total number of orders",
      labels: [:status, :currency]
    )

    Prometheus.Histogram.new(
      name: :order_value_euros,
      help: "Order value in euros",
      buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
    )
  end
end

# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Setup Prometheus
    MyApp.Prometheus.setup()

    children = [
      # ... other children
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

### Phoenix Plugs Integration

```elixir
# lib/my_app_web/endpoint.ex
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # Prometheus metrics exporter
  plug Prometheus.PlugExporter, 
    path: "/metrics",
    format: :text

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug MyAppWeb.Router
end

# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # Instrument all routes
  pipeline :instrumented do
    plug Prometheus.PlugInstrumenter, 
      labels: [:method, :path, :status]
  end

  pipeline :api do
    plug :instrumented
    plug :accepts, ["json"]
  end

  scope "/api", MyAppWeb do
    pipe_through :api
    # Routes automatically instrumented
  end
end
```

### Ecto Metrics

```elixir
# lib/my_app/repo.ex
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use Prometheus.Ecto.Repo
end

# This automatically collects:
# - ecto_repo_query_total
# - ecto_repo_query_duration_seconds
# - ecto_repo_queue_time_seconds
```

### Business Metrics Instrumentation

```elixir
# lib/my_app/services/user_service.ex
defmodule MyApp.Services.UserService do
  def create_user(attrs) do
    with {:ok, user} <- do_create_user(attrs) do
      # Increment counter
      Prometheus.Counter.inc(
        name: :users_created_total,
        labels: [attrs["source"] || "web"]
      )

      {:ok, user}
    end
  end

  defp do_create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end

# lib/my_app/services/order_service.ex
defmodule MyApp.Services.OrderService do
  def create_order(attrs) do
    with {:ok, order} <- do_create_order(attrs) do
      # Record order metrics
      Prometheus.Counter.inc(
        name: :orders_total,
        labels: [order.status, order.currency]
      )

      Prometheus.Histogram.observe(
        name: :order_value_euros,
        value: order.total_euros
      )

      {:ok, order}
    end
  end

  defp do_create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Connection Metrics

```elixir
# lib/my_app/services/connection_tracker.ex
defmodule MyApp.Services.ConnectionTracker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def track_connection(type) do
    Prometheus.Gauge.inc(name: :active_connections, labels: [type])
  end

  def untrack_connection(type) do
    Prometheus.Gauge.dec(name: :active_connections, labels: [type])
  end

  # Update metrics periodically
  def init(_) do
    schedule_metrics_update()
    {:ok, %{}}
  end

  def handle_info(:update_metrics, state) do
    # Update process metrics
    Prometheus.Gauge.set(
      name: :active_connections,
      value: :erlang.system_info(:process_count),
      labels: ["erlang"]
    )

    schedule_metrics_update()
    {:noreply, state}
  end

  defp schedule_metrics_update do
    Process.send_after(self(), :update_metrics, 10_000)
  end
end

# Add to supervisor
defmodule MyApp.Application do
  def start(_type, _args) do
    children = [
      MyApp.Services.ConnectionTracker,
      # ... other children
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

### WebSocket Metrics

```elixir
# lib/my_app_web/channels/user_socket.ex
defmodule MyAppWeb.UserSocket do
  use Phoenix.Socket

  channel "room:*", MyAppWeb.RoomChannel

  def connect(_params, socket, _connect_info) do
    MyApp.Services.ConnectionTracker.track_connection("websocket")
    {:ok, socket}
  end

  def id(_socket), do: nil
end

# Custom WebSocket metrics
defmodule MyAppWeb.WebSocketMetrics do
  def track_message(channel) do
    Prometheus.Counter.inc(
      name: :websocket_messages_total,
      labels: [channel]
    )
  end

  def track_connection() do
    Prometheus.Counter.inc(name: :websocket_connections_total)
  end

  def track_disconnection() do
    Prometheus.Counter.inc(name: :websocket_disconnections_total)
  end
end
```

### Prometheus Server Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'my_app'
    static_configs:
      - targets: ['localhost:4000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "alerts/*.yml"
```

### Alerting Rules

```yaml
# alerts/my_app.yml
groups:
  - name: my_app
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          description: "Error rate is {{ $value }}"

      - alert: HighResponseTime
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High response time
          description: "95th percentile is {{ $value }}s"

      - alert: DatabaseSlowQueries
        expr: |
          histogram_quantile(0.95, rate(ecto_repo_query_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: Slow database queries
          description: "95th percentile query time is {{ $value }}s"

      - alert: LowOrderRate
        expr: |
          sum(rate(orders_total[1h])) < 10
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: Low order rate
          description: "Order rate dropped to {{ $value }}/s"
```

### Testing Prometheus Metrics

```elixir
# test/my_app/prometheus_test.exs
defmodule MyApp.PrometheusTest do
  use ExUnit.Case

  setup do
    # Reset Prometheus between tests
    Prometheus.Registry.clear()
    MyApp.Prometheus.setup()
    :ok
  end

  test "increments user creation counter" do
    UserService.create_user(%{"email" => "test@example.com", "source" => "web"})

    value = Prometheus.Counter.value(
      name: :users_created_total,
      labels: ["web"]
    )

    assert value == 1
  end

  test "records request duration histogram" do
    # Simulate HTTP request
    Prometheus.Histogram.observe(
      name: :http_request_duration_seconds,
      value: 0.123,
      labels: ["GET", "/api/users"]
    )

    # Check histogram values
    histogram = Prometheus.Histogram.value(
      name: :http_request_duration_seconds,
      labels: ["GET", "/api/users"]
    )

    assert histogram.sum > 0
    assert histogram.count == 1
  end
end
```

### Production Configuration

```elixir
# config/prod.exs
config :my_app, MyAppWeb.Endpoint,
  # Enable metrics collection
  instrumenters: [Prometheus.PhoenixInstrumenter]

# Prometheus configuration
config :prometheus, MyApp.Prometheus,
  # Disable default metrics in tests
  disable_metrics: false,
  # Use appropriate buckets for production
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0]

# Time window for rate calculations
config :prometheus,
  global_labels: [environment: :production, app: "my_app"]
```
