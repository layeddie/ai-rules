# Phoenix + Ash + LiveView Template

**Description**: Complete Phoenix web application with Ash framework for domain-driven development and LiveView for real-time UI.

**Project Structure**:
```
[Project Name]/
├── .ai_rules/                   # Symlink to .ai_rules repository
├── .serena/                       # Serena MCP indexes
├── .opencode/                     # OpenCode configurations
├── mix.exs                        # Mix configuration
├── config/
│   ├── config.exs                 # Application config
│   ├── dev.exs                  # Dev environment
│   ├── runtime.exs              # Runtime config
│   └── test.exs                  # Test config
├── lib/
│   └── [Project Name]/
│       ├── application.ex
│       └── repo.ex
├── lib/[Project Name]/
│       ├── ash/
│       │   └── resources/
│       └── api/
│       └── accounts/
│       │       └── user/
│       │           ├── create.ex
│       │           ├── update.ex
│       │           └── delete.ex
│       │       └── api.ex
│       └── [Domain]/
│       │           └── domain.ex
│       └── [Resources]/
│       │       └── resource.ex
│       └── └── action.ex
│       └── └── create.ex
│       ├── [Submodules]/
│       │   ├── registry.ex
│       │   ├── cache_worker.ex
│       │   └── session_manager.ex
│       └── notifications/
│       │       └── pubsub.ex
└── lib/[Project Name]_web/
│       ├── endpoint.ex
│       ├── router.ex
│       └── live/
│           ├── dashboard_live.ex
│           └── [Pages]/
│               ├── user_index_live.ex
│               ├── user_show_live.ex
│               └── user_edit_live.ex
├── priv/
│   └── repo/
│       │   └── migrations/
├── test/
│   └── [Project Name]/
│       ├── support/
│       └── data_case.ex
│       ├── conn_case.ex
│       └── doctest.ex
│       ├── [Submodules]/
│       │   └── [Pages]/
│       └── accounts_test.exs
└── project_requirements.md
```

---

## Mix Dependencies

```elixir
defmodule [Project Name].MixProject do
  use Mix.Project

  def project do
    [
      app: :"[Project Name]",
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      build_embedded: "lib/[Project Name]_web",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: ["sh"]
    ]
  end

  def application do
    [
      mod: {[Project Name].Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_view, "~> 1.0.0"},
      {:ash, "~> 3.4", github: "ash-project/ash-core", override: [ash_phoenix]},
      {:ash_phoenix, "~> 3.0"},
      {:ash_authentication, "~> 4.0", github: "ash-auth-phoenix"},
      {:ash_postgres, "~> 2.0"},
      {:ash_json_api, "~> 1.4"},
      {:phoenix_html, "~> 3.3"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.0"},
      {:bcrypt_elixir, "~> 3.0"},
      {:comeonin, "~> 0.17"}
      {:ex_machina, "~> 0.8"}
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.17"}
    ]
  end
end
```

---

## Configuration

### config/config.exs
```elixir
import Config

config :[Project Name], [Project Name]Web.Endpoint,
  pubsub_server_name: [Project Name].PubSub,
  live_view: [signing_salt: "Jl/1W7FJv8M2sF7S+J7Jd8l8Q7R5l3gK3cX8q7F4m3g="]

config :[Project Name], :ecto,
  repo: [Project Name].Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10,
  ssl: true
  database_url: System.get_env("DATABASE_URL"),
  stacktrace: true,
  log: true
  migration_timestamps: [utc_datetime: true]

# Configure Ash
config :ash,
  api_policies?: true,
  show_key?: false,
  actor_persistence?: true

# Configure Phoenix LiveView
config :phoenix_live_view,
  signing_salt: System.get_env("LIVE_VIEW_SIGNING_SALT"),
  live_reload_on_build_errors: true
```

### config/dev.exs
```elixir
import Config

config :[Project Name], [Project Name]Web.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  secret_key_name: System.get_env("SECRET_KEY_NAME")

config :[Project Name], :dev, :ecto,
  repo: [Project Name].Repo,
  show_sensitive_data_on_connection_error: true,
  show_stacktrace: true

config :[Project Name], :logger, level: :info
```

---

## Application Module

### lib/[Project Name]/application.ex
```elixir
defmodule [Project Name].Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Database
      [Project Name].Repo,
      
      # Registry
      {Registry, keys: :unique, name: [Project Name].Registry},
      
      # Domain supervisors
      {[Project Name].Accounts.Supervisor, []},
      {[Project Name].Billing.Supervisor, []},
      
      # Submodules
      {[Project Name].Registry, keys: :unique, name: [Project Name].Registry},
      {[Project Name].Cache.Worker, []},
      {[Project Name].Session.Manager, []},
      
      # Web endpoint
      [Project Name]Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: [Project Name].Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### lib/[Project Name]/repo.ex
```elixir
defmodule [Project Name].Repo do
  use Ecto.Repo,
  otp_app: :[Project Name]

  @impl true
  def init(_type, state) do
    {:ok, state}
  end
end
```

---

## Ash Resources Example

### lib/[Project Name]/ash/resources/user/user.ex
```elixir
defmodule [Project Name].Ash.Resources.User do
  use Ash.Resource

  attributes do
    uuid_primary_key :id,
    attribute :email, :string, allow_nil?: false,
    attribute :password, :string, allow_nil?: false,
    attribute :password_hash, :string,
    attribute :name, :string,
    timestamps()
  end

  actions do
    create :register,
    read :by_email,
    update :update,
    destroy :delete,
    read :by_id,
    update :update_profile
    destroy :delete
  end

  relationships do
    has_many :posts, [Project Name].Ash.Resources.Post
    has_one :profile, [Project Name].Ash.Resources.Profile
  end
end
```

### lib/[Project Name]/ash/api/user.ex
```elixir
defmodule [Project Name].Ash.Api.User do
  use Ash.Api

  resources do
    read :read,
    create :create
  end
end
```

---

## LiveView Example

### lib/[Project Name]_web/live/dashboard_live.ex
```elixir
defmodule [Project Name]Web.DashboardLive do
  use [Project Name]Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      users: list_users(),
      changeset: change_user_form()
    )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_user", %{"user" => user_params}, socket) do
    case [Project Name].Ash.Api.User.update(user.id, user_params) do
      {:ok, updated_user} ->
        {:noreply, assign(socket, users: list_users(), changeset: change_user_form())}
      
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.container>
      <.header>
        <h1>Users</h1>
        <.live_component module={[Project Name]Web.UserCard} users={@users} />
      </.header>

      <.live_component :if={@live_component} module={[Project Name]Web.NewUserForm}
        changeset={@changeset}
        user={@new_user} />
      </.live_component>
      <.form let={f} for="save_user" phx-submit="save_user">
        <.input type="text" name="user[name]" id="user[id]" placeholder="Enter email" />
        <.input type="password" name="user[password]" placeholder="Enter password" />
        <button type="submit">Save</button>
      </.form>
    </.container>
    """
  end
end
```

---

## Testing Example

### test/[Project Name]/support/data_case.ex
```elixir
defmodule [Project Name].Support.DataCase do
  use ExUnit.Case

  alias [Project Name].Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup tags: [async: false]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout([Project Name].Repo])
  end
end
```

### test/[Project Name]/accounts/user/create_test.exs
```elixir
defmodule [Project Name].Accounts.User.CreateTest do
  use [Project Name].Support.DataCase

  alias [Project Name].Ash.Resources.User
  alias [Project Name].Ash.Api.User

  describe "create/1" do
    test "creates user with valid attributes" do
      attrs = %{email: "test@example.com", password: "password123"}
      
      assert {:ok, %User{} = user} = [Project Name].Ash.Resources.User.create(attrs)
      assert user.email == "test@example.com"
      refute user.password_hash  # Password should be hashed
    end
  end
end
```

---

## Deployment

### rel/config.exs
```elixir
import Config

config :[Project Name], :prod,
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  secret_key_name: System.fetch_env!("SECRET_KEY_NAME")
```

---

## Instructions

### 1. Initialize Project

```bash
# Navigate to your project directory
cd ~/projects/2025
my_app

# Create project using .ai_rules template
bash .ai_rules/scripts/init_project.sh my_app ~/projects/2025/.ai_rules phoenix-ash-liveview

# 2. Edit project_requirements.md
# Configure your project requirements
vim project_requirements.md

# 3. Start plan session (Terminal 1)
opencode --config .opencode/opencode.plan.json

# 4. Start build session (Terminal 2)
opencode --config .opencode/opencode.build.json

# 5. Start review session (  (Terminal 3, optional)
opencode --config .opencode/opencode.review.json
```

### 2. Multi-Session Workflow

```
┌─────────────────────────────────────────────────────────┐
│                   Terminal 1 (Plan Session)                 │
│  opencode --config .opencode/opencode.plan.json              │
│  ├── Agent: Architect                                      │
│  ├── Tools: mgrep (primary), grep, websearch              │
│  ├── Model: Claude 3.5 Sonnet (API)                     │
│  └── Output: project_requirements.md, file structure plan  │
└─────────────────────────────────────────────────────────┘
                              ↓
                    (plan written to files)
                              ↓
┌─────────────────────────────────────────────────────────┐
│                   Terminal 2 (Build Session)                  │
│  opencode --config .opencode/opencode.build.json             │
│  ├── Agent: Orchestrator                                   │
│  ├── Tools: Serena (primary), grep, write                 │
│  ├── Model: DeepSeek Coder 16B (Ollama)               │
│  └── Output: Implementation code, tests                     │
└─────────────────────────────────────────────────────────┘
```

---

**This template provides a complete Phoenix + Ash + LiveView starting point for Elixir/BEAM development.**
