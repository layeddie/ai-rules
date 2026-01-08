# Elixir-Scribe Folder Structure

**Purpose**: Self-documenting folder structure pattern from elixir-scribe tool.

## Quick Start

```bash
# Generate with elixir-scribe
mix scribe.gen.domain Catalog
mix scribe.gen.html Catalog Product products name:string desc:string
mix scribe.gen.html Warehouse Stock stocks product_id:integer quantity:integer
```

## Pattern Structure

### Domain Resource Action Layout
```bash
lib/
└── my_app/
    └── domains/
            └── catalog/
                        └── product/
                                    ├── create.ex
                                    ├── update.ex
                                    ├── delete.ex
                                    ├── list.ex
                                    ├── new.ex
                                    ├── read.ex
                                    ├── export.ex
```

### Web Layer Structure
```bash
lib/
└── my_app_web/
    └── domains/
            └── catalog/
                        └── product/
                                    ├── create.ex
                                    ├── update.ex
                                    ├── delete.ex
                                    ├── list.ex
                                    ├── new.ex
                                    ├── read.ex
                                    └── export.ex
```

## Key Characteristics

### 1. Self-Documenting
- **Instant project understanding**: Folder structure reveals all domains, resources, and actions
- **Navigation aid**: Developers can find features in seconds
- **Onboarding**: New team members understand structure quickly

### 2. Single Responsibility
- **One action per file**: Enforces SRP at file system level
- **Clear module boundaries**: Each action is a separate module
- **Reduced complexity**: Smaller, focused modules

### 3. Domain Boundaries
- **Explicit structure**: Domains are top-level folders
- **Resource groups**: Resources are subfolders within domains
- **Action files**: Actions are individual files

## Implementation Pattern

### Action Module Pattern
```elixir
defmodule MyApp.Domains.Catalog.Product.Create do
  @moduledoc """
  Creates a new product in the catalog.
  """

  alias MyApp.Repo
  alias MyApp.Domains.Catalog.Product

  @spec call(map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Domain API Pattern
```elixir
defmodule MyApp.Domains.Catalog.Product do
  @moduledoc """
  Product domain API - public interface for product operations.
  """

  alias MyApp.Domains.Catalog.Product.{Create, Update, Delete, List}

  @spec create(map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs), do: Create.call(attrs)

  @spec update(integer(), map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs), do: Update.call(id, attrs)

  @spec delete(integer()) :: :ok | {:error, Ecto.Changeset.t()}
  def delete(id), do: Delete.call(id)

  @spec list(map()) :: {:ok, [Product.t()]} | {:error, term()}
  def list(opts \\ %{}), do: List.call(opts)
end
```

## Comparison with Domain Resource Action

| Aspect | elixir-scribe | Domain Resource Action |
|--------|----------------|----------------------|
| **File organization** | Explicit folders | Module-based (flexible) |
| **Self-documenting** | High (folder names) | Medium (need to document) |
| **SRP enforcement** | High (file system) | Medium (developer discipline) |
| **Flexibility** | Low (fixed structure) | High (any pattern) |
| **Learning curve** | Steep (new pattern) | Moderate (well-known) |
| **Tooling support** | Mix generators | Manual implementation |
| **Framework** | None required | Required for Ash |

## Integration with ai-rules

### When to Use
- **Nures/embedded projects**: Embedded systems benefit from explicit structure
- **Simple Elixir services**: No framework needed
- **Learning teams**: elixir-scribe enforces good practices
- **Framework-agnostic**: Works without Ash or Phoenix

### Roles to Reference
- **Architect**: Choose elixir-scribe for Nures/embedded projects
- **Orchestrator**: Follow folder structure when using elixir-scribe
- **Backend Specialist**: Implement Domain Resource Action pattern within folders
- **Frontend Specialist**: Adapt web layer structure for elixir-scribe

## Best Practices

1. **Single Responsibility**: One action per module file
2. **Domain boundaries**: Separate domains contain related resources
3. **Public APIs**: Domain API modules provide contracts
4. **Delegated concerns**: External services in separate modules
5. **Documentation**: Folder structure serves as documentation
