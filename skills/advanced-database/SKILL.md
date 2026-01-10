# Advanced Database Patterns Skill

## Overview

Comprehensive guide to advanced database patterns, strategies, and techniques for production Elixir applications.

## When to Use Advanced Database Patterns

**Use advanced patterns when:**
- Your application has high throughput requirements (>1000 req/s)
- You need to support multi-tenancy
- You're experiencing database performance bottlenecks
- You need to scale reads or writes horizontally
- You require complex data modeling patterns
- You need to implement database-level optimizations

**Stick with basic patterns when:**
- Your application has low-to-moderate throughput (<1000 req/s)
- You have a single tenant system
- Your database performance is acceptable
- Your data model is simple and straightforward

## Connection Pooling

### DO: Configure Connection Pools Properly

```elixir
# config/dev.exs
config :my_app, MyApp.Repo,
  pool_size: 10,
  queue_target: 100,  # Queue target
  queue_interval: 1000,  # Wait time before checkout

# config/prod.exs
config :my_app, MyApp.Repo,
  pool_size: 20,  # Adjust based on database server capacity
  queue_target: 1000,
  queue_interval: 5000,
  # Enable prepared statements
  prepare: :unnamed,
  # Enable statement cache
  statement_cache_size: 100

# config/test.exs
config :my_app, MyApp.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 50  # Larger pool for parallel tests
```

### DON'T: Use Pool Size = Ecto.Adapters.SQL.Sandbox Pool Size

```elixir
# DON'T: Too large for production
config :my_app, MyApp.Repo,
  pool_size: 100  # Too large for most production databases

# DO: Calculate pool size based on database capacity
# Formula: (max_connections - reserved_for_other_apps) / number_of_app_nodes
# Example: Postgres max_connections = 100, reserved = 20, nodes = 2
# Pool size = (100 - 20) / 2 = 40 per node
config :my_app, MyApp.Repo,
  pool_size: 40
```

## Multi-Tenancy Strategies

### 1. Shared Database, Shared Schema (Tenant Isolation at Row Level)

```elixir
# Schema with tenant_id
defmodule MyApp.Accounts.Tenant do
  use Ecto.Schema

  schema "tenants" do
    field :name, :string
    field :subdomain, :string

    has_many :users, MyApp.Accounts.User
    has_many :posts, MyApp.Content.Post
  end
end

# User schema with tenant_id
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
    belongs_to :tenant, MyApp.Accounts.Tenant

    has_many :posts, MyApp.Content.Post
  end
end

# Query scope for tenant
defmodule MyApp.TenantQueries do
  def for_tenant(queryable, tenant_id) do
    where(queryable, [t], t.tenant_id == ^tenant_id)
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    User
    |> MyApp.TenantQueries.for_tenant(tenant_id)
    |> Repo.all()
  end

  def get_user!(tenant_id, user_id) do
    User
    |> MyApp.TenantQueries.for_tenant(tenant_id)
    |> Repo.get!(user_id)
  end
end
```

### 2. Tenant Middleware

```elixir
# Tenant middleware for Phoenix
defmodule MyApp.TenantPlugs do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant_id = get_tenant_from_subdomain(conn)

    if tenant_id do
      conn
      |> assign(:tenant_id, tenant_id)
      |> assign(:tenant, get_tenant(tenant_id))
    else
      conn
      |> send_resp(404, "Tenant not found")
      |> halt()
    end
  end

  defp get_tenant_from_subdomain(conn) do
    host = conn.host
    subdomain = String.split(host, ".") |> List.first()

    case Repo.get_by(Tenant, subdomain: subdomain) do
      nil -> nil
      tenant -> tenant.id
    end
  end

  defp get_tenant(tenant_id), do: Repo.get(Tenant, tenant_id)
end

# Usage in router
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug MyApp.TenantPlugs
    plug MyApp.Plugs.SetTenant  # Set tenant context
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end
end
```

### 3. Database Isolation (Separate Schema per Tenant)

```elixir
# Dynamic repo for tenant
defmodule MyApp.TenantRepo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  def set_tenant_prefix(tenant_id) do
    config = Application.get_env(:my_app, __MODULE__)

    new_config =
      Keyword.put(config, :pool_size, 10)
      |> Keyword.put(:url, "postgres://user:pass@localhost/myapp_tenant_#{tenant_id}")

    Application.put_env(:my_app, __MODULE__, new_config)
  end
end

# Usage
defmodule MyApp.Accounts do
  def create_user(tenant_id, attrs) do
    MyApp.TenantRepo.set_tenant_prefix(tenant_id)

    %User{}
    |> User.changeset(attrs)
    |> MyApp.TenantRepo.insert()
  end
end
```

## Database Replication

### Read/Write Split

```elixir
# Primary database (write)
config :my_app, MyApp.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_PRIMARY_URL"),
  pool_size: 10

# Replica database (read)
config :my_app, MyApp.ReadReplicaRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_REPLICA_URL"),
  pool_size: 20,
  # Set to read-only for safety
  # PostgreSQL: default_transaction_read_only = 'on'

# Usage
defmodule MyApp.Accounts do
  def list_users do
    # Read from replica
    MyApp.ReadReplicaRepo.all(User)
  end

  def create_user(attrs) do
    # Write to primary
    MyApp.Repo.insert(User.changeset(%User{}, attrs))
  end

  def update_user(user, attrs) do
    # Write to primary
    user
    |> User.changeset(attrs)
    |> MyApp.Repo.update()
  end
end
```

### Replica Selection Strategy

```elixir
defmodule MyApp.ReplicaSelector do
  @replicas [
    MyApp.ReadReplicaRepo1,
    MyApp.ReadReplicaRepo2,
    MyApp.ReadReplicaRepo3
  ]

  def select_replica(query_type \\ :read) do
    case query_type do
      :read -> choose_replica()
      :write -> MyApp.Repo
    end
  end

  defp choose_replica do
    # Round-robin selection
    index = :ets.update_counter(:replica_index, :current, 1, {1, 0})
    rem(index, length(@replicas))
    |> Enum.at(@replicas)
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users do
    repo = MyApp.ReplicaSelector.select_replica(:read)
    repo.all(User)
  end

  def get_user!(id) do
    repo = MyApp.ReplicaSelector.select_replica(:read)
    repo.get!(User, id)
  end

  def create_user(attrs) do
    repo = MyApp.ReplicaSelector.select_replica(:write)
    repo.insert(User.changeset(%User{}, attrs))
  end
end
```

## Database Sharding

### Horizontal Sharding

```elixir
defmodule MyApp.Sharding do
  @shard_count 10

  def shard_for_id(id) do
    rem(id, @shard_count)
  end

  def get_repo_for_shard(shard_id) do
    Module.concat([MyApp, "RepoShard#{shard_id}"])
  end

  def get_repo_for_id(id) do
    shard_id = shard_for_id(id)
    get_repo_for_shard(shard_id)
  end
end

# Usage
defmodule MyApp.Accounts do
  def create_user(attrs) do
    user = User.changeset(%User{}, attrs)

    case user do
      %{valid?: true} ->
        repo = MyApp.Repo.get_repo_for_id(user.changes.id)
        repo.insert(user)
    end
  end

  def get_user!(id) do
    repo = MyApp.Repo.get_repo_for_id(id)
    repo.get!(User, id)
  end
end

# Configuration for multiple repos
for shard_id <- 0..9 do
  config :my_app, Module.concat([MyApp, "RepoShard#{shard_id}"]),
    adapter: Ecto.Adapters.Postgres,
    url: "postgres://user:pass@localhost/myapp_shard_#{shard_id}",
    pool_size: 5
end
```

## Database Indexing Strategies

### Composite Indexes

```elixir
# Migration
defmodule MyApp.Repo.Migrations.AddCompositeIndexes do
  use Ecto.Migration

  def change do
    # Index for queries filtering by user_id and status
    create index(:posts, [:user_id, :status])

    # Index for queries filtering by user_id, status, and created_at
    create index(:posts, [:user_id, :status, :created_at])
  end
end

# Query uses composite index
defmodule MyApp.Content do
  def list_user_posts(user_id, status, limit \\ 20) do
    Post
    |> where([p], p.user_id == ^user_id and p.status == ^status)
    |> order_by([p], desc: p.created_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
```

### Partial Indexes

```elixir
# Migration
defmodule MyApp.Repo.Migrations.AddPartialIndexes do
  use Ecto.Migration

  def change do
    # Index only published posts (reduces index size)
    create index(:posts, [:user_id], where: "status = 'published'")

    # Index only active users
    create index(:users, [:email], where: "status = 'active'")
  end
end

# Query uses partial index
defmodule MyApp.Content do
  def list_published_posts(user_id) do
    Post
    |> where([p], p.user_id == ^user_id and p.status == :published)
    |> Repo.all()
  end
end
```

### Expression Indexes

```elixir
# Migration
defmodule MyApp.Repo.Migrations.AddExpressionIndexes do
  use Ecto.Migration

  def change do
    # Index on lowercased email for case-insensitive searches
    execute "CREATE INDEX users_email_lower_idx ON users(LOWER(email))"

    # Index on JSONB field
    execute "CREATE INDEX posts_metadata_idx ON posts USING GIN(metadata)"
  end
end

# Query uses expression index
defmodule MyApp.Accounts do
  def find_user_by_email(email) do
    User
    |> where([u], fragment("LOWER(?) = ?", u.email, ^String.downcase(email)))
    |> Repo.one()
  end
end
```

## Database Migration Strategies

### Zero-Downtime Migrations

```elixir
# Phase 1: Add new column (nullable)
defmodule MyApp.Repo.Migrations.Phase1AddNewColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :new_email, :string  # Nullable for now
    end
  end
end

# Phase 2: Backfill data (after deployment)
defmodule MyApp.Repo.Migrations.Phase2BackfillData do
  use Ecto.Migration

  def up do
    execute """
      UPDATE users
      SET new_email = email
      WHERE new_email IS NULL
    """
  end

  def down do
    execute "UPDATE users SET new_email = NULL"
  end
end

# Phase 3: Update application code to use new column
# (Application code update, not migration)

# Phase 4: Make column non-nullable
defmodule MyApp.Repo.Migrations.Phase3MakeColumnRequired do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :new_email, :string, null: false
    end
  end
end

# Phase 5: Remove old column
defmodule MyApp.Repo.Migrations.Phase5RemoveOldColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :email
    end

    rename table(:users), :new_email, to: :email
  end
end
```

## Database Partitioning

### Range Partitioning

```elixir
# Migration
defmodule MyApp.Repo.Migrations.CreatePartitionedPostsTable do
  use Ecto.Migration

  def change do
    create table(:posts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid
      add :content, :text
      add :created_at, :naive_datetime

      timestamps()
    end

    # Partition by month
    execute """
      CREATE TABLE posts_2026_01 PARTITION OF posts
      FOR VALUES FROM ('2026-01-01') TO ('2026-02-01')
    """

    execute """
      CREATE TABLE posts_2026_02 PARTITION OF posts
      FOR VALUES FROM ('2026-02-01') TO ('2026-03-01')
    """
  end
end
```

## Common Pitfalls

### DON'T: Ignore Connection Pooling Configuration

```elixir
# DON'T: Default configuration in production
config :my_app, MyApp.Repo,
  pool_size: 10  # Default may not be optimal

# DO: Calculate optimal pool size based on database capacity
config :my_app, MyApp.Repo,
  pool_size: 40  # Based on database max_connections
```

### DON'T: Use SELECT * When You Need Specific Columns

```elixir
# DON'T: Loading all columns
def list_users do
  Repo.all(User)
end

# DO: Select only needed columns
def list_users do
  User
  |> select([u], {u.id, u.name, u.email})
  |> Repo.all()
end
```

## Related Skills

- [Ecto Query Analysis](../ecto-query-analysis/SKILL.md) - Query performance analysis
- [Database Architect](../../roles/database-architect.md) - Database design patterns

## Related Patterns

- [Migration Strategies](../migration_strategies.md) - Database migration patterns
- [Circuit Breaker](../circuit_breaker.md) - Database failure handling
