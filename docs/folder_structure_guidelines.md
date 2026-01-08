# Folder Structure Guidelines

**Purpose**: Documentation of multiple valid approaches to Single Responsibility Principle and folder organization in Elixir.

## Principles

### Single Responsibility Principle (SRP)

All approaches aim for:
1. **Single responsibility per module**: Each module/action has one clear purpose
2. **Clear boundaries**: Separation of concerns between modules
3. **Maintainability**: Easy to understand, modify, and test
4. **Reduced complexity**: Smaller, focused modules

## Approach 1: Ash Framework (Declarative DSL)

### Structure

```elixir
# Actions defined in resource DSL
defmodule MyApp.Blog.Post do
  use Ash.Resource

  actions do
    create :create
    update :update
    destroy :delete
    read :read
    list :list
  end
end
```

### Characteristics

- **Declarative DSL**: Actions defined within resource
- **Framework enforcement**: Ash provides patterns and conventions
- **Code generation**: Automatic APIs and migrations
- **Type safety**: Ash changesets with validation
- **Implicit structure**: Structure derived from DSL

### When to Use

- **Phoenix + Ash applications**: Web apps with LiveView/JSON API
- **Complex domains**: Business rules, authorization, policies
- **Team with Ash experience**: Familiar with DSL and patterns

---

## Approach 2: elixir-scribe (Explicit Folders)

### Structure

```bash
lib/
└── my_app/
    └── domains/
            └── blog/
                    └── post/
                        ├── create.ex
                        ├── update.ex
                        ├── delete.ex
                        └── list.ex
```

### Characteristics

- **Explicit folders**: Clear file structure reveals organization
- **One action per file**: Enforces SRP at file system level
- **Manual discipline**: Developer maintains structure via file naming
- **Self-documenting**: Folder names serve as documentation
- **Framework-agnostic**: Works without Ash or Phoenix

### When to Use

- **Nures embedded projects**: Explicit structure aids navigation in constrained environments
- **Framework-agnostic code**: No framework required
- **Learning teams**: elixir-scribe enforces good practices
- **Small teams**: Manual coordination is manageable

---

## Approach 3: Domain Resource Action (Flexible)

### Structure

```elixir
# Team chooses level of structure
# Option A: Separate files (elixir-scribe-like)
lib/my_app/domains/blog/post/
  ├── create.ex
  ├── update.ex
  ├── delete.ex

# Option B: Single module (traditional)
lib/my_app/domains/blog/post.ex
  # All actions in one module
```

### Characteristics

- **Flexibility**: Team chooses structure level
- **Standard ai-rules**: Follow Domain Resource Action pattern
- **Documented choice**: Structure specified in project requirements
- **Clear boundaries**: Maintains SRP principle
- **Maintainable**: Any valid approach when applied consistently

### When to Use

- **Existing codebases**: Maintain existing structure
- **Team consensus**: Document agreed approach in project requirements
- **Mixed frameworks**: Works with Ash, Phoenix, or vanilla Elixir
- **Gradual migration**: Can evolve structure over time

---

## Decision Framework

### Quick Decision Matrix

| Criteria | Ash Framework | elixir-scribe | Domain Resource Action (Flexible) |
|-----------|----------------|----------------|------------------------------|-------------------------------|
| **Learning curve** | ⚠️ Moderate (Ash) | ⚠️ Steep (new pattern) | ✅ Low (standard) |
| **Team size** | ✅ Any size (Ash) | ⚠️ Small preferred (elixir-scribe) | ✅ Any size (flexible) |
| **Code gen** | ✅ Excellent | ❌ None | ⚠️ Medium (varies) |
| **Self-documenting** | ⚠️ Medium (need docs) | ✅ High (folders) | ⚠️ Medium (need docs) |
| **Flexibility** | ⚠️ Framework opinionated | ✅ Highest (no framework) | ✅ Highest (any pattern) |
| **Framework** | ⚠️ Requires Ash | None required | None required | None required |

---

## Best Practices

### All Approaches

1. **Clear purpose**: Each module/action has single responsibility
2. **Public APIs**: Domain APIs provide contracts, hide implementation
3. **Separate concerns**: External services in separate modules
4. **Documentation**: Explain SRP in @moduledoc
5. **Testing**: Unit test each responsibility independently

### Implementation Steps

1. **Define in project_requirements.md**: Document chosen approach
2. **Follow naming conventions**: Elixir naming throughout
3. **Maintain public APIs**: Domain APIs abstract implementation
4. **Document decisions**: ADRs for architectural choices
5. **Stay consistent**: Don't mix approaches within same domain
