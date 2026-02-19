# Multi-Tenancy Patterns

**Last Reviewed**: 2026-02-19  
**Source Material**: Elixir community best practices, Ash framework patterns

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Building SaaS applications with multiple tenants
- Implementing tenant isolation strategies
- Designing multi-tenant database schemas
- Managing tenant-specific configurations

❌ **DON'T use this file when**:
- Single-tenant applications
- Simple user isolation (use standard auth patterns)
- Multi-user apps without tenant separation

**See also**:
- `skills/advanced-database/SKILL.md` - Database strategies
- `patterns/ash_resources.md` - Ash resource patterns

---

## Pattern 1: Shared Database with Tenant ID (Row-Level Isolation)

**Problem**: Need tenant isolation with simple implementation

✅ **Solution**: Use `tenant_id` column in all tables

```elixir
# Migration
defmodule MyApp.Repo.Migrations.AddTenantId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :tenant_id, references(:tenants, on_delete: :delete_all)
    end

    alter table(:posts) do
      add :tenant_id, references(:tenants, on_delete: :delete_all)
    end

    # Add indexes for tenant queries
    create index(:users, [:tenant_id])
    create index(:posts, [:tenant_id])
  end
end

# Schema
defmodule MyApp.Accounts.User do
  use Ecto.Schema

  schema "users" do
    field :email, :string
    field :name, :string
    belongs_to :tenant, MyApp.Accounts.Tenant

    timestamps()
  end
end

# Query scope
defmodule MyApp.TenantScope do
  def for_tenant(queryable, tenant_id) do
    where(queryable, [t], t.tenant_id == ^tenant_id)
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    User
    |> MyApp.TenantScope.for_tenant(tenant_id)
    |> Repo.all()
  end
end
```

**When to use**: Small to medium SaaS applications, simple tenant isolation needs

**Reference**: skills/advanced-database/SKILL.md - Multi-tenancy section

---

## Pattern 2: Tenant Context Plug (Phoenix)

**Problem**: Need to identify current tenant in Phoenix requests

✅ **Solution**: Use Plug to extract tenant from subdomain or header

```elixir
# Tenant plug
defmodule MyAppWeb.Plugs.SetTenant do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_tenant_id(conn) do
      {:ok, tenant_id} ->
        conn
        |> assign(:tenant_id, tenant_id)
        |> assign(:tenant, get_tenant(tenant_id))

      :error ->
        conn
        |> send_resp(404, "Tenant not found")
        |> halt()
    end
  end

  defp get_tenant_id(conn) do
    # Option 1: Subdomain
    tenant_id = get_tenant_from_subdomain(conn)

    # Option 2: Header
    # tenant_id = get_req_header(conn, "x-tenant-id") |> List.first()

    # Option 3: Session
    # tenant_id = get_session(conn, :tenant_id)

    case tenant_id do
      nil -> :error
      id -> {:ok, id}
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

# Router
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug MyAppWeb.Plugs.SetTenant
  end

  scope "/", MyAppWeb do
    pipe_through :browser
    # All routes now have tenant context
  end
end

# Usage in controller
defmodule MyAppWeb.UserController do
  def index(conn, _params) do
    tenant_id = conn.assigns.tenant_id
    users = Accounts.list_users(tenant_id)
    render(conn, :index, users: users)
  end
end
```

**When to use**: Phoenix web applications with subdomain-based tenancy

---

## Pattern 3: Schema-Based Isolation (PostgreSQL)

**Problem**: Need stronger tenant isolation at database level

✅ **Solution**: Use separate PostgreSQL schemas per tenant

```elixir
# Migration for new tenant
defmodule MyApp.TenantSetup do
  def create_tenant_schema(tenant_id) do
    # Create schema
    Repo.query!("CREATE SCHEMA tenant_#{tenant_id}")

    # Run tenant-specific migrations
    Ecto.Migrator.with_repo(Repo, fn repo ->
      migrations_path = Application.app_dir(:my_app, "priv/tenant_migrations")
      Ecto.Migrator.run(repo, migrations_path, :up, all: true, prefix: "tenant_#{tenant_id}")
    end)
  end

  def drop_tenant_schema(tenant_id) do
    Repo.query!("DROP SCHEMA tenant_#{tenant_id} CASCADE")
  end
end

# Query with tenant prefix
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    User
    |> Ecto.Queryable.to_query()
    |> Map.put(:prefix, "tenant_#{tenant_id}")
    |> Repo.all()
  end

  def create_user(tenant_id, attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(prefix: "tenant_#{tenant_id}")
  end
end

# Tenant plug updates
defmodule MyAppWeb.Plugs.SetTenant do
  def call(conn, _opts) do
    case get_tenant_id(conn) do
      {:ok, tenant_id} ->
        # Set tenant context in process dictionary
        Process.put(:tenant_id, tenant_id)

        conn
        |> assign(:tenant_id, tenant_id)
        |> assign(:tenant, get_tenant(tenant_id))

      :error ->
        conn
        |> send_resp(404, "Tenant not found")
        |> halt()
    end
  end
end
```

**When to use**: Strong isolation requirements, compliance needs, large tenants

---

## Pattern 4: Database Per Tenant

**Problem**: Need complete tenant isolation with separate databases

✅ **Solution**: Dynamic repository configuration per tenant

```elixir
# Dynamic repo
defmodule MyApp.TenantRepo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  def for_tenant(tenant_id) do
    # Get tenant-specific config
    config = tenant_config(tenant_id)

    # Start dynamic repo if not running
    case Repo.start_link(config) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end

    # Return repo module with dynamic name
    {__MODULE__, tenant_id}
  end

  defp tenant_config(tenant_id) do
    [
      adapter: Ecto.Adapters.Postgres,
      url: "postgres://user:pass@localhost/myapp_tenant_#{tenant_id}",
      pool_size: 10,
      name: :"tenant_repo_#{tenant_id}"
    ]
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    tenant_repo = MyApp.TenantRepo.for_tenant(tenant_id)
    tenant_repo.all(User)
  end
end
```

**When to use**: Enterprise SaaS, strict compliance, maximum isolation

---

## Pattern 5: Tenant-Aware Ecto Queries

**Problem**: Ensure all queries include tenant filtering

✅ **Solution**: Use Ecto query interceptors

```elixir
# Query interceptor
defmodule MyApp.TenantQueryInterceptor do
  import Ecto.Query

  def inject_tenant(query, tenant_id) do
    case has_tenant_field?(query) do
      true -> where(query, [t], t.tenant_id == ^tenant_id)
      false -> query
    end
  end

  defp has_tenant_field?(query) do
    # Check if query source has tenant_id field
    # Simplified implementation
    true
  end
end

# Repo wrapper
defmodule MyApp.TenantRepo do
  def all(queryable, tenant_id) do
    queryable
    |> MyApp.TenantQueryInterceptor.inject_tenant(tenant_id)
    |> Repo.all()
  end

  def get!(queryable, tenant_id, id) do
    queryable
    |> MyApp.TenantQueryInterceptor.inject_tenant(tenant_id)
    |> Repo.get!(id)
  end

  def insert(changeset, tenant_id) do
    changeset
    |> Ecto.Changeset.put_change(:tenant_id, tenant_id)
    |> Repo.insert()
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    MyApp.TenantRepo.all(User, tenant_id)
  end

  def get_user!(tenant_id, user_id) do
    MyApp.TenantRepo.get!(User, tenant_id, user_id)
  end
end
```

**When to use**: Prevent accidental cross-tenant queries, enforce tenant isolation

---

## Pattern 6: Tenant Configuration

**Problem**: Need tenant-specific configuration and feature flags

✅ **Solution**: Store tenant config in database or ETS

```elixir
# Tenant schema with config
defmodule MyApp.Accounts.Tenant do
  use Ecto.Schema

  schema "tenants" do
    field :name, :string
    field :subdomain, :string
    field :config, :map, default: %{}

    timestamps()
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :subdomain, :config])
    |> validate_required([:name, :subdomain])
    |> unique_constraint(:subdomain)
  end
end

# Tenant config manager
defmodule MyApp.TenantConfig do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(tenant_id, key, default \\ nil) do
    GenServer.call(__MODULE__, {:get, tenant_id, key, default})
  end

  def get_all(tenant_id) do
    GenServer.call(__MODULE__, {:get_all, tenant_id})
  end

  def reload(tenant_id) do
    GenServer.cast(__MODULE__, {:reload, tenant_id})
  end

  # GenServer callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:get, tenant_id, key, default}, _from, state) do
    config = Map.get(state, tenant_id, load_config(tenant_id))
    value = Map.get(config, key, default)
    {:reply, value, state}
  end

  def handle_call({:get_all, tenant_id}, _from, state) do
    config = Map.get(state, tenant_id, load_config(tenant_id))
    {:reply, config, state}
  end

  def handle_cast({:reload, tenant_id}, state) do
    new_state = Map.put(state, tenant_id, load_config(tenant_id))
    {:noreply, new_state}
  end

  defp load_config(tenant_id) do
    case Repo.get(Tenant, tenant_id) do
      nil -> %{}
      tenant -> tenant.config
    end
  end
end

# Usage
defmodule MyAppWeb.FeatureController do
  def show(conn, %{"feature" => feature}) do
    tenant_id = conn.assigns.tenant_id

    if MyApp.TenantConfig.get(tenant_id, "features.#{feature}", false) do
      # Feature enabled for this tenant
      render(conn, :show, feature: feature)
    else
      conn
      |> put_flash(:error, "Feature not available")
      |> redirect(to: "/")
    end
  end
end
```

**When to use**: Feature flags, tenant-specific settings, dynamic configuration

---

## Pattern 7: Multi-Tenancy with Ash Framework

**Problem**: Need multi-tenancy with Ash resources

✅ **Solution**: Use Ash's built-in multi-tenancy support

```elixir
# Ash resource with multi-tenancy
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string
    attribute :name, :string
  end

  relationships do
    belongs_to :tenant, MyApp.Accounts.Tenant
  end

  postgres do
    table "users"
    repo MyApp.Repo
  end

  # Ash handles tenant filtering automatically
  multitenancy do
    strategy :attribute
    attribute :tenant_id
    global? true  # Allow global queries for admins
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :for_tenant do
      filter expr(tenant_id == ^actor.tenant_id)
    end
  end
end

# Domain with tenant context
defmodule MyApp.Accounts do
  use Ash.Domain

  resources do
    resource MyApp.Accounts.User
    resource MyApp.Accounts.Tenant
  end
end

# Usage
defmodule MyApp.Accounts do
  def list_users(tenant_id) do
    User
    |> Ash.Query.for_read(:for_tenant, %{}, tenant: tenant_id)
    |> Ash.read!()
  end

  def create_user(tenant_id, attrs) do
    User
    |> Ash.Changeset.for_create(:create, attrs, tenant: tenant_id)
    |> Ash.create!()
  end
end

# Tenant plug for Ash
defmodule MyAppWeb.Plugs.SetAshTenant do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_tenant_id(conn) do
      {:ok, tenant_id} ->
        # Set Ash tenant context
        Ash.set_tenant(tenant_id)

        conn
        |> assign(:tenant_id, tenant_id)

      :error ->
        conn
        |> send_resp(404, "Tenant not found")
        |> halt()
    end
  end
end
```

**When to use**: Projects using Ash framework

---

## Pattern 8: Testing Multi-Tenancy

**Problem**: Need to test multi-tenant functionality

✅ **Solution**: Use test helpers for tenant isolation

```elixir
# Test case
defmodule MyApp.AccountsTest do
  use MyApp.DataCase

  setup do
    {:ok, tenant1} = create_tenant("tenant1")
    {:ok, tenant2} = create_tenant("tenant2")

    {:ok, tenant1: tenant1, tenant2: tenant2}
  end

  test "lists users for tenant", %{tenant1: tenant1, tenant2: tenant2} do
    # Create users for different tenants
    {:ok, user1} = create_user(tenant1.id, "user1@example.com")
    {:ok, user2} = create_user(tenant2.id, "user2@example.com")

    # Check tenant isolation
    users = Accounts.list_users(tenant1.id)
    assert length(users) == 1
    assert hd(users).id == user1.id

    users = Accounts.list_users(tenant2.id)
    assert length(users) == 1
    assert hd(users).id == user2.id
  end

  test "prevents cross-tenant access", %{tenant1: tenant1, tenant2: tenant2} do
    {:ok, user1} = create_user(tenant1.id, "user1@example.com")

    # Try to access user from different tenant
    assert_raise Ecto.NoResultsError, fn ->
      Accounts.get_user!(tenant2.id, user1.id)
    end
  end

  # Helper functions
  defp create_tenant(name) do
    %Tenant{}
    |> Tenant.changeset(%{name: name, subdomain: name})
    |> Repo.insert()
  end

  defp create_user(tenant_id, email) do
    %User{tenant_id: tenant_id}
    |> User.changeset(%{email: email, name: "Test User"})
    |> Repo.insert()
  end
end
```

**When to use**: Testing multi-tenant applications

---

## Common Anti-Patterns

### ❌ Forgetting Tenant Filter in Queries

```elixir
# DON'T: Query without tenant filter
def list_users do
  Repo.all(User)  # Returns ALL users across tenants!
end

# DO: Always include tenant filter
def list_users(tenant_id) do
  User
  |> where([u], u.tenant_id == ^tenant_id)
  |> Repo.all()
end
```

### ❌ Hardcoded Tenant IDs

```elixir
# DON'T: Hardcode tenant IDs
def list_users do
  User
  |> where([u], u.tenant_id == 1)  # Hardcoded!
  |> Repo.all()
end

# DO: Get tenant from context
def list_users(conn) do
  tenant_id = conn.assigns.tenant_id
  User
  |> where([u], u.tenant_id == ^tenant_id)
  |> Repo.all()
end
```

### ❌ Inconsistent Tenant Handling

```elixir
# DON'T: Mix different isolation strategies
def list_users(tenant_id) do
  if use_schema_isolation?() do
    # Schema-based
    User
    |> Map.put(:prefix, "tenant_#{tenant_id}")
    |> Repo.all()
  else
    # Row-based
    User
    |> where([u], u.tenant_id == ^tenant_id)
    |> Repo.all()
  end
end

# DO: Choose one strategy and stick with it
```

---

## Performance Considerations

### Indexing

```elixir
# Always index tenant_id columns
create index(:users, [:tenant_id])
create index(:posts, [:tenant_id])

# Composite indexes for common queries
create index(:posts, [:tenant_id, :status])
create index(:posts, [:tenant_id, :user_id])
```

### Caching

```elixir
# Cache tenant config in ETS
defmodule MyApp.TenantCache do
  use GenServer

  def get_config(tenant_id) do
    case :ets.lookup(:tenant_config, tenant_id) do
      [{^tenant_id, config}] -> config
      [] -> load_and_cache(tenant_id)
    end
  end
end
```

---

## References

**Primary Sources**:
- Elixir community best practices
- Ash framework documentation
- PostgreSQL multi-tenancy patterns

**Related Patterns**:
- `skills/advanced-database/SKILL.md` - Database strategies
- `patterns/ash_resources.md` - Ash resource patterns
- `patterns/migration_strategies.md` - Migration patterns

---

**Last Updated**: 2026-02-19
