# Ash Framework Resource Patterns

**Last Reviewed**: 2025-01-06  
**Source Material**: Alembic + Medium (Kamaro) + DevTalk + ElixirForum + Ash-HQ (2025)

---

## Quick Lookup: When to Use This File

✅ **Use this file when**:
- Designing Ash resources for data models
- Defining actions, relationships, and policies
- Building APIs with Ash
- Implementing multi-tenancy
- Optimizing Ash for performance

❌ **DON'T use this file when**:
- Building simple CRUD with plain Ecto (unless integrating Ash)
- Writing manual queries instead of using Ash DSL
- Not needing resource-based design patterns

**See also**:
- `migration_strategies.md` - Ash migration patterns
- `phoenix_controllers.md` - Phoenix controller patterns (for integration)
- `error_handling.md` - Ash error handling patterns

---

## Pattern 1: Domain-Driven Resource Design

**Concept**: Model your domain first, let Ash derive the rest

✅ **Example**:
```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: ["MyApp.Accounts"]

  attributes do
    uuid_primary_key :id
    attribute :email, :string, allow_nil?: false
    attribute :name, :string
    attribute :inserted_at, :utc_datetime, allow_nil?: false
    attribute :updated_at, :utc_datetime, allow_nil?: false
  end

  relationships do
    belongs_to :organization, MyApp.Accounts.Organization
    has_many :posts, MyApp.Blog.Post
  end

  actions do
    create :default
    read :default
    update :default
    destroy :default
  end

  postgres do
    custom_indexes do
      index :users_email_index, on: [:email]
    end
  end
end
```

**Reference**: Alembic - "Everything you need to know about Ash Framework" (2025)

---

## Pattern 2: Ash API for Resource Orchestration

**Concept**: Create an API module to group resources

✅ **Example**:
```elixir
defmodule MyApp.Accounts do
  use Ash.Api

  resources do
    resource MyApp.Accounts.User
    resource MyApp.Accounts.Organization
    resource MyApp.Blog.Post
  end
end

defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      MyApp.Accounts,  # Register Ash API
      MyAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Reference**: Ash-HQ documentation

---

## Pattern 3: Resource Splitting for Maintainability

**Problem**: Large resources become unwieldy

✅ **Solution**: Split resources by domain boundaries (from Medium Kamaro - Part 32)

```elixir
# Before (large resource)
defmodule MyApp.Content.Item do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :author_id, :uuid
    attribute :category_id, :uuid
    attribute :tags, {:array, :string}
    attribute :status, :string
    attribute :created_at, :utc_datetime
    attribute :updated_at, :utc_datetime
    attribute :published_at, :utc_datetime
    attribute :metadata, :map
    attribute :view_count, :integer
    attribute :like_count, :integer
    attribute :comment_count, :integer
  end

  relationships do
    belongs_to :author, MyApp.Content.Author
    belongs_to :category, MyApp.Content.Category
    has_many :tags, MyApp.Content.Tag
    has_many :comments, MyApp.Content.Comment
  end

  actions do
    create :default
    read :default
    update :default
    destroy :default
  end

  postgres do
    check_constraints do
      check_constraint :valid_status, constraint: :check_status, check: ~w(draft|published|archived)
    end
  end

  calculations do
    calculate :is_published, expr: status == :published
  end
end

# After (split resources)
defmodule MyApp.Content.Item.Core do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :body, :string
    attribute :author_id, :uuid
    attribute :status, :string
    attribute :created_at, :utc_datetime
    attribute :updated_at, :utc_datetime
  end

  relationships do
    belongs_to :author, MyApp.Content.Author
  end

  actions do
    create :default
    read :default
    update :default
  end
end

defmodule MyApp.Content.Item.Publishing do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :published_at, :utc_datetime
    attribute :metadata, :map
    attribute :view_count, :integer
    attribute :like_count, :integer
    attribute :comment_count, :integer
  end

  actions do
    create :default
    read :default
    update :default
  end
end
```

**Reference**: Kamaro Lambert - "Part 32: How To Split Your BIG Ash Resources" (Medium, 2025)

---

## Pattern 4: Ash Actions with Policies

**Concept**: Ash provides first-class authorization built-in

✅ **Example**:
```elixir
defmodule MyApp.Accounts.User do
  use Ash.Resource,
    domain: ["MyApp.Accounts"],
    extensions: [Ash.Policy.Authorizer]

  attributes do
    uuid_primary_key :id
    attribute :email, :string
    attribute :is_admin, :boolean, default: false
    attribute :organization_id, :uuid
  end

  relationships do
    belongs_to :organization, MyApp.Accounts.Organization
  end

  actions do
    create :default
    read :default
    update :default
    destroy :default
  end

  policies do
    policy always true do
      authorize_if is_admin()

      authorize_if actor_attribute_equals(:organization_id, :organization_id)
    end
  end
end

defmodule MyApp.Accounts.Policies do
  use Ash.Policy

  def is_admin(actor, resource, action) do
    actor.is_admin == true
  end

  def actor_attribute_equals(actor, field, resource) do
    Map.get(actor, field) == Map.get(resource, field)
  end
end
```

**Reference**: Alembic - "Ash Framework best in class security"

---

## Pattern 5: Custom Action Types

**Concept**: Beyond standard CRUD, define custom action types

✅ **Example**:
```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :title, :string
    attribute :slug, :string
    attribute :content, :string
    attribute :author_id, :uuid
    attribute :status, :atom, default: :draft
    attribute :published_at, :utc_datetime
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    action :publish do
      argument :published_at, {:uuid, :utc_datetime} do
        allow_nil? false
      end

      change fn changeset, actor, _context do
        Ash.Changeset.change_attribute(changeset, :status, :published)
        Ash.Changeset.change_attribute(changeset, :published_at, actor.published_at)
        Ash.Changeset.set_argument(changeset, :published_at, changeset.arguments.published_at)
      end

      # Custom logic
      validate fn changeset, _context do
        if changeset.arguments.published_at < changeset.attributes.published_at do
          Ash.Changeset.add_error(changeset, :published_at, "Cannot publish in the future")
        end
      end

      run fn changeset, _context do
        # Post to social media, send notifications, etc.
        {:ok, changeset}
      end
    end

    action :unpublish do
      argument :unpublished_at, {:uuid, :utc_datetime}

      change fn changeset, actor, _context do
        Ash.Changeset.change_attribute(changeset, :status, :draft)
        Ash.Changeset.change_attribute(changeset, :unpublished_at, actor.unpublished_at)
        Ash.Changeset.set_argument(changeset, :unpublished_at, changeset.arguments.unpublished_at)
      end

      run fn changeset, _context do
        {:ok, changeset}
      end
    end
  end

  postgres do
    indexes do
      index :posts_slug_index, on: [:slug], unique: true
    end
  end
end
```

**Reference**: Ash-HQ - Action documentation

---

## Pattern 6: Code Generation with Igniter

**Problem**: Repetitive resource creation is slow

✅ **Solution**: Use Igniter for code generation

```elixir
# Generate new resource
mix ash.gen.resource MyApp.Blog.Post posts title:string slug:string content:string status:atom author_id:uuid

# Or use Igniter programmatically
mix igniter.install ash_postgres
```

**Reference**: `docs/igniter-how-to.md` - Igniter usage guide

---

## Pattern 7: Ash + Phoenix Integration

**Concept**: Use Ash resources in Phoenix LiveViews

✅ **Example**:
```elixir
defmodule MyAppWeb.PostLive do
  use MyAppWeb, :live_view

  alias MyApp.Blog

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :posts, Blog.list_posts())}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign(socket, :post, Blog.get_post!(id))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    case Blog.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        socket
        |> put_flash(:info, "Post updated successfully")
        |> push_navigate(to: ~p"/posts/#{post.slug}")

      {:error, changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> put_flash(:error, "Failed to update post")
        |> noreply()
    end
  end
end
```

**Reference**: Ash-HQ - Phoenix integration documentation

---

## Pattern 8: Testing Ash Resources

**Problem**: Testing Ash resources requires proper test setup (from DevTalk 2025)

✅ **Solution**: Use Ash.DataCase and Ash.ToAsh

```elixir
defmodule MyApp.AccountsTest do
  use Ash.DataCase,
    domain: ["MyApp.Accounts"]

  alias MyApp.Accounts.User

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{
        email: "user@example.com",
        name: "Test User",
        organization_id: Ecto.UUID.generate()
      }

      assert {:ok, user} = Ash.create!(User, attrs)
      assert user.email == attrs.email
      assert user.name == attrs.name
    end

    test "returns error with invalid email" do
      attrs = %{
        email: "invalid",
        name: "Test User"
      }

      assert {:error, changeset} = Ash.create(User, attrs)
      assert Ash.Changeset.error?(changeset)
      assert "email" in Keyword.keys(Ash.Changeset.errors(changeset))
    end
  end
end
```

**Reference**: Elixir Forum - "Testing Ash - share your design and best practices" (2025)

---

## Pattern 9: Migrations with Ash

**Concept**: Ash generates migrations from resource definitions

✅ **Solution**: Let Ash manage migrations

```elixir
# In config/config.exs
config :my_app, :ash_domains,
  resources: [MyApp.Accounts, MyApp.Blog],
  allow_migrations?: true

# Generate and run migrations
mix ash.generate_migrations

# In production
mix ash.install
```

**Reference**: Ash-HQ - Migration documentation

---

## Pattern 10: API Generation (GraphQL, JSON:API)

**Concept**: Ash can auto-generate APIs from resources

✅ **Solution**: Use AshPostgres and AshJsonApi

```elixir
# In mix.exs
defp deps do
  [
    {:ash_postgres, "~> 2.0"},
    {:ash_json_api, "~> 1.0"},
    {:ash_graphql, "~> 1.0"}
  ]
end

# In router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MyAppWeb do
    pipe_through :api

    # JSON:API routes
    forward "/users", AshJsonApi.Router
    forward "/posts", AshJsonApi.Router

    # GraphQL routes
    forward "/graphql", AshGraphql.Router
  end
end
```

**Reference**: Alembic - "Ash Framework: API generation"

---

## Testing Patterns for This File

### Unit Testing Ash Resources
```elixir
test "create_user creates user with valid attributes" do
  assert {:ok, user} = Ash.create!(User, attrs)
  assert user.email == attrs.email
  assert user.is_active == true
end
```

### Integration Testing with Ash APIs
```elixir
test "POST /api/users creates user", %{conn: conn} do
  attrs = %{email: "new@example.com", name: "Test User"}

  conn
  |> post("/api/users", user: attrs)
  |> json_response(201)

  assert %{"id" => _} = json_response(conn, 201)
end
```

---

## References

**Primary Sources**:
- Alembic - "Everything you need to know about Ash Framework" (2025)
- Kamaro Lambert - "Ash Framework for Phoenix Developers [PDF]" (2025)
- DevTalk Forum - "Ash Framework: How to test changes to resources?" (2025)
- Ash-HQ - Official documentation
- Elixir Forum - "Testing Ash - share your design and best practices" (2025)

**Related Patterns**:
- `migration_strategies.md` - Ash migration patterns
- `phoenix_controllers.md` - Phoenix controller patterns
- `error_handling.md` - Ash error handling patterns

**Deep Dives**:
- `docs/igniter-how-to.md` - Igniter usage guide
- Ash Framework Book by Kamaro Lambert - Comprehensive Ash guide

**Community**:
- Elixir Forum - Ash Framework forum
- Ash-HQ Discord
