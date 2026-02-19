# OpenTelemetry Integration Example

## Complete OpenTelemetry Setup for Elixir/Phoenix

### Dependencies

```elixir
# mix.exs
def deps do
  [
    {:opentelemetry, "~> 1.3"},
    {:opentelemetry_api, "~> 1.2"},
    {:opentelemetry_exporter, "~> 1.3"},
    {:opentelemetry_phoenix, "~> 1.1"},
    {:opentelemetry_ecto, "~> 1.1"},
    {:opentelemetry_liveview, "~> 1.0"},
    {:opentelemetry_oban, "~> 1.0"}
  ]
end
```

### Application Configuration

```elixir
# config/runtime.exs
import Config

config :opentelemetry,
  resource: [
    service_name: "my_app",
    service_version: "1.0.0",
    deployment_environment: config_env()
  ]

# OTLP exporter configuration
config :opentelemetry, :exporter,
  otlp: [
    endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT") || "http://localhost:4317",
    headers: [
      {"api-key", System.get_env("OTEL_API_KEY") || ""}
    ]
  ]

# Samplers
config :opentelemetry, :sampler,
  parent_based: [
    root: [
      trace_id_ratio_based: [
        probability: String.to_float(System.get_env("OTEL_SAMPLING_PROBABILITY") || "0.1")
      ]
    ]
  ]

# Span processors
config :opentelemetry, :processor,
  batch: [
    scheduling_delay_ms: 5000,
    max_queue_size: 2048,
    exporting_timeout_ms: 30_000
  ]
```

### Tracer Module

```elixir
# lib/my_app/tracer.ex
defmodule MyApp.Tracer do
  require OpenTelemetry.Tracer, as: Tracer
  require OpenTelemetry.Span, as: Span

  def with_span(name, attributes \\ %{}, fun) do
    Tracer.with_span name, attributes do
      fun.()
    end
  end

  def add_span_attributes(attributes) when is_map(attributes) do
    Enum.each(attributes, fn {key, value} ->
      Span.set_attribute(key, value)
    end)
  end

  def add_span_event(name, attributes \\ %{}) do
    Span.add_event(name, attributes)
  end

  def record_exception(exception, stacktrace) do
    Span.record_exception(exception, stacktrace)
  end

  def set_span_status(status, description \\ "") do
    case status do
      :ok -> Span.set_status(:ok, description)
      :error -> Span.set_status(:error, description)
    end
  end
end
```

### Phoenix Integration

```elixir
# lib/my_app_web/endpoint.ex
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :my_app

  # OpenTelemetry middleware
  plug OpenTelemetry.Plug, 
    app_name: :my_app,
    service_name: "my_app_web"

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

  # Add tracing to all routes
  pipeline :traced do
    plug OpenTelemetry.Plug, 
      app_name: :my_app,
      service_name: "my_app_web"
  end

  pipeline :api do
    plug :traced
    plug :accepts, ["json"]
  end

  scope "/api", MyAppWeb do
    pipe_through :api
    # Routes automatically traced
  end
end
```

### Ecto Integration

```elixir
# lib/my_app/repo.ex
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use OpenTelemetryEcto.Repo,
    service_name: "my_app"
end

# Application supervisor
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Setup Ecto telemetry
    :telemetry.attach(
      "opentelemetry-ecto",
      [:my_app, :repo, :query],
      &OpenTelemetryEcto.handle_event/4,
      %{}
    )

    children = [
      # ... other children
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

### Oban Integration

```elixir
# config/config.exs
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [default: 10],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 604_800}
  ]

# lib/my_app/workers/example_worker.ex
defmodule MyApp.Workers.ExampleWorker do
  use Oban.Worker, queue: :default
  use OpenTelemetry.Oban

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Automatically traced
    process_job(args)
  end

  defp process_job(args) do
    # Add custom span attributes
    MyApp.Tracer.add_span_attributes(%{
      "job.type" => "example",
      "job.id" => args["id"]
    })

    # Do work
    :ok
  end
end
```

### Custom Tracing Example

```elixir
# lib/my_app/services/user_service.ex
defmodule MyApp.Services.UserService do
  require OpenTelemetry.Tracer, as: Tracer

  def create_user(attrs) do
    Tracer.with_span "user.create", %{
      "user.email" => attrs["email"],
      "user.source" => attrs["source"]
    } do
      with {:ok, user} <- validate_user(attrs),
           {:ok, user} <- persist_user(user),
           {:ok, user} <- send_welcome_email(user) do
        MyApp.Tracer.add_span_event("user.created", %{
          "user.id" => user.id
        })
        
        {:ok, user}
      else
        {:error, reason} ->
          MyApp.Tracer.set_span_status(:error, inspect(reason))
          {:error, reason}
      end
    end
  end

  defp validate_user(attrs) do
    Tracer.with_span "user.validate" do
      # Validation logic
      {:ok, attrs}
    end
  end

  defp persist_user(user_attrs) do
    Tracer.with_span "user.persist" do
      %User{}
      |> User.changeset(user_attrs)
      |> Repo.insert()
    end
  end

  defp send_welcome_email(user) do
    Tracer.with_span "user.email.welcome", %{
      "email.to" => user.email
    } do
      # Email sending logic
      {:ok, user}
    end
  end
end
```

### Distributed Context Propagation

```elixir
# lib/my_app/services/external_api.ex
defmodule MyApp.Services.ExternalAPI do
  require OpenTelemetry.Tracer, as: Tracer

  def call_external_service(data) do
    Tracer.with_span "external.api.call" do
      # Get current context
      ctx = OpenTelemetry.Ctx.get_current()
      
      # Inject context into HTTP headers
      headers = inject_trace_context(ctx, [])
      
      # Make HTTP call with trace context
      Req.post("https://api.example.com/endpoint",
        json: data,
        headers: headers
      )
    end
  end

  defp inject_trace_context(ctx, headers) do
    OpenTelemetry.Propagator.Text.inject(ctx, headers, fn headers, key, value ->
      [{key, value} | headers]
    end)
  end

  def receive_webhook(headers, body) do
    # Extract trace context from incoming request
    ctx = OpenTelemetry.Propagator.Text.extract(headers, fn headers, key ->
      List.keyfind(headers, key, 0)
    end)

    # Link to parent span
    Tracer.with_span "webhook.receive", %{}, ctx do
      process_webhook(body)
    end
  end
end
```

### Sampling Strategies

```elixir
# config/config.exs

# Head-based sampling (default)
config :opentelemetry, :sampler,
  parent_based: [
    root: [
      trace_id_ratio_based: [
        probability: 0.1  # Sample 10% of traces
      ]
    ]
  ]

# Custom sampler
# lib/my_app/custom_sampler.ex
defmodule MyApp.CustomSampler do
  @behaviour :otel_sampler

  @impl true
  def setup(opts) do
    %{
      base_rate: Keyword.get(opts, :base_rate, 0.1),
      health_check_rate: Keyword.get(opts, :health_check_rate, 0.01)
    }
  end

  @impl true
  def should_sample(ctx, trace_id, links, span_name, span_kind, attributes, opts) do
    # Sample health checks at lower rate
    if is_health_check?(span_name, attributes) do
      {:drop, [], opts}
    else
      # Sample other requests at base rate
      if :rand.uniform() < opts.base_rate do
        {:record_and_sample, [], opts}
      else
        {:drop, [], opts}
      end
    end
  end

  defp is_health_check?(span_name, attributes) do
    span_name =~ "/health" or
    attributes["http.route"] == "/health"
  end

  @impl true
  def description(_opts), do: "Custom sampler for MyApp"
end

# Use custom sampler
config :opentelemetry, :sampler, {MyApp.CustomSampler, [base_rate: 0.2]}
```

### Testing with OpenTelemetry

```elixir
# test/support/otel_test.ex
defmodule MyApp.OtelTest do
  use ExUnit.Case

  setup do
    # Start OpenTelemetry test mode
    OpenTelemetry.Tracer.set_test_mode()
    
    on_exit(fn ->
      OpenTelemetry.Tracer.reset()
    end)
  end

  test "creates user with correct span" do
    UserService.create_user(%{email: "test@example.com"})

    # Assert span was created
    assert span = OpenTelemetry.Tracer.get_span("user.create")
    
    # Verify span attributes
    assert span.attributes["user.email"] == "test@example.com"
    
    # Verify span events
    assert Enum.any?(span.events, fn event ->
      event.name == "user.created"
    end)
  end
end
```

### Jaeger/Zipkin Export

```elixir
# For Jaeger
config :opentelemetry, :exporter,
  jaeger: [
    endpoint: "http://localhost:14268/api/traces",
    service_name: "my_app"
  ]

# For Zipkin
config :opentelemetry, :exporter,
  zipkin: [
    endpoint: "http://localhost:9411/api/v2/spans",
    service_name: "my_app",
    local_endpoint: %{
      service_name: "my_app",
      ipv4: "127.0.0.1",
      port: 4000
    }
  ]
```

### Production Considerations

```elixir
# config/prod.exs
config :opentelemetry,
  resource: [
    service_name: "my_app",
    service_version: System.get_env("APP_VERSION"),
    deployment_environment: :production,
    host_name: System.get_env("HOSTNAME")
  ]

# Tune batch processor for production
config :opentelemetry, :processor,
  batch: [
    scheduling_delay_ms: 10_000,  # 10 seconds
    max_queue_size: 10_000,
    exporting_timeout_ms: 60_000
  ]

# Higher sampling in production
config :opentelemetry, :sampler,
  parent_based: [
    root: [
      trace_id_ratio_based: [
        probability: 0.05  # 5% sampling
      ]
    ]
  ]
```
