---
name: containerization
description: Docker and Kubernetes deployment patterns for Elixir/Phoenix applications
---

# Containerization Skill

Use this skill when deploying Elixir/Phoenix applications with Docker and Kubernetes.

## When to Use

- Creating Docker images for Elixir applications
- Deploying to Kubernetes clusters
- Setting up CI/CD pipelines
- Multi-stage Docker builds
- Container orchestration
- Health checks and monitoring

## Docker Fundamentals

### Multi-Stage Dockerfile

```dockerfile
# Dockerfile
# Build stage
FROM hexpm/elixir:1.17.3-erlang-27.1-debian-bookworm-20240904 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy assets and compile
COPY assets assets
RUN cd assets && npm install && npm run deploy

# Compile project
COPY lib lib
COPY priv priv
RUN mix compile

# Build release
COPY config config
COPY rel rel
RUN mix release

# Runtime stage
FROM debian:bookworm-20240904-slim

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    openssl \
    libncurses5 \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Create non-root user
RUN useradd -m -s /bin/bash appuser

# Copy release from builder
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/my_app ./

USER appuser

ENV HOME=/app

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Start application
CMD ["bin/my_app", "start"]
```

### Docker Compose for Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=postgres://user:password@db:5432/my_app_dev
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - MIX_ENV=dev
    volumes:
      - .:/app
      - deps:/app/deps
      - _build:/app/_build
    depends_on:
      - db
      - redis
    command: mix phx.server

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=my_app_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  deps:
  _build:
  postgres_data:
```

### Development Dockerfile

```dockerfile
# Dockerfile.dev
FROM hexpm/elixir:1.17.3-erlang-27.1-debian-bookworm-20240904

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    nodejs \
    npm \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=dev

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . .

CMD ["mix", "phx.server"]
```

## Kubernetes Deployment

### Deployment

```yaml
# k8s/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-registry/my-app:latest
        ports:
        - containerPort: 4000
        
        # Environment variables from ConfigMap and Secrets
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: database-url
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: secret-key-base
        - name: MIX_ENV
          value: "prod"
        
        # Resource limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 4000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health
            port: 4000
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Volume mounts
        volumeMounts:
        - name: config
          mountPath: /app/config/runtime.exs
          subPath: runtime.exs
          readOnly: true
      
      volumes:
      - name: config
        configMap:
          name: my-app-config
```

### Service

```yaml
# k8s/service.yml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 4000
  type: LoadBalancer
```

### Ingress

```yaml
# k8s/ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: my-app-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

### ConfigMap

```yaml
# k8s/configmap.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  runtime.exs: |
    import Config

    config :my_app, MyApp.Repo,
      url: System.get_env("DATABASE_URL"),
      pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "10"),
      ssl: true

    config :my_app, MyAppWeb.Endpoint,
      http: [
        port: String.to_integer(System.get_env("PORT") || "4000"),
        transport_options: [socket_opts: [:inet6]]
      ],
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      url: [host: System.get_env("HOST"), port: 443, scheme: "https"],
      server: true
```

### Secrets

```yaml
# k8s/secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secrets
type: Opaque
data:
  database-url: cG9zdGdyZXM6Ly91c2VyOnBhc3N3b3JkQGRiOjU0MzIvbXlfYXBwX3Byb2Q=
  secret-key-base: WW91ckB1cmVuZG9tU2VjcmV0S2V5QmFzZUZvckBQcm9kdWN0aW9uR29lc0hlcmU=
```

### Horizontal Pod Autoscaler

```yaml
# k8s/hpa.yml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ secrets.REGISTRY_URL }}
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ secrets.REGISTRY_URL }}/my-app:${{ github.sha }}
          ${{ secrets.REGISTRY_URL }}/my-app:latest
        cache-from: type=registry,ref=${{ secrets.REGISTRY_URL }}/my-app:latest
        cache-to: type=inline
    
    - name: Deploy to Kubernetes
      uses: steebchen/kubectl@v2.0.0
      with:
        config: ${{ secrets.KUBE_CONFIG }}
        command: set image deployment/my-app my-app=${{ secrets.REGISTRY_URL }}/my-app:${{ github.sha }}
    
    - name: Verify deployment
      uses: steebchen/kubectl@v2.0.0
      with:
        config: ${{ secrets.KUBE_CONFIG }}
        command: rollout status deployment/my-app
```

## Elixir-Specific Optimizations

### Release Configuration

```elixir
# rel/config.exs
import Config

config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "10"),
  ssl: true

config :my_app, MyAppWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  url: [host: System.get_env("HOST"), port: 443, scheme: "https"],
  server: true,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# config/releases.exs
import Config

config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE") || "10"),
  ssl: true

config :my_app, MyAppWeb.Endpoint,
  server: true,
  http: [port: 4000]
```

### Application Supervisor

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      MyAppWeb.Telemetry,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Health Check Endpoint

```elixir
# lib/my_app_web/controllers/health_controller.ex
defmodule MyAppWeb.HealthController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    health_status = check_health()

    conn
    |> put_status(health_status.status)
    |> json(%{
      status: health_status.message,
      timestamp: DateTime.utc_now(),
      version: Application.spec(:my_app, :vsn)
    })
  end

  defp check_health do
    checks = [
      check_database(),
      check_redis()
    ]

    if Enum.all?(checks, fn {status, _} -> status == :ok end) do
      %{status: 200, message: "healthy"}
    else
      %{status: 503, message: "degraded"}
    end
  end

  defp check_database do
    case MyApp.Repo.query("SELECT 1") do
      {:ok, _} -> {:ok, "database"}
      _ -> {:error, "database"}
    end
  end

  defp check_redis do
    case MyApp.Redis.command(["PING"]) do
      {:ok, _} -> {:ok, "redis"}
      _ -> {:error, "redis"}
    end
  end
end

# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :api

  get "/health", HealthController, :index
end
```

## Best Practices

### Docker Best Practices

1. **Use multi-stage builds** - Reduce image size
2. **Run as non-root user** - Security
3. **Use specific versions** - Reproducibility
4. **Minimize layers** - Faster builds
5. **Use .dockerignore** - Exclude unnecessary files
6. **Set health checks** - Container orchestration

### Kubernetes Best Practices

1. **Set resource limits** - Prevent resource starvation
2. **Use health checks** - Ensure availability
3. **Use ConfigMaps/Secrets** - Configuration management
4. **Implement HPA** - Auto-scaling
5. **Use namespaces** - Resource isolation
6. **Set up monitoring** - Observability

### Elixir-Specific Best Practices

1. **Use releases** - Production deployments
2. **Set EPMD port** - Kubernetes networking
3. **Configure clustering** - Distributed Erlang
4. **Use environment variables** - Configuration
5. **Monitor BEAM** - Process metrics

## Related Skills

- **nix**: Alternative deployment with NixOS
- **observability**: Monitoring and logging
- **security-patterns**: Container security
- **otp-patterns**: BEAM clustering
