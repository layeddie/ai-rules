# Single Responsibility Implementation Patterns

**Purpose**: Quick reference for implementing Single Responsibility Principle across different approaches.

## SRP in Ash Framework

### Pattern: Actions in DSL

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource

  actions do
    create :create do
      accept [:title, :content]
      
      changeset do
        validate_required([:title, :content])
        validate_length(changeset, :title, max: 200)
        validate_format(changeset, :content, match: ~r/^[\w\s.,]{10,}/)
      end
      
      change fn changeset ->
        # Business logic here - SRP unit
        put_change(changeset, :slug, slugify(get_change(changeset, :title)))
      end
    end
  end
end
```

### Key Points

- **Actions are SRP units** within Ash resource DSL
- **Hooks** allow cross-cutting concerns without mixing responsibilities
- **Changesets** validate inputs, actions keep business logic focused

## SRP in elixir-scribe

### Pattern: One File Per Action

```elixir
lib/my_app/domains/blog/post/create.ex
defmodule MyApp.Domains.Blog.Post.Create do
  @moduledoc """
  Creates a new blog post.
  """

  alias MyApp.Repo
  alias MyApp.Domains.Blog.Post

  @spec call(map()) :: {:ok, Post.t()} | {:error, Ecto.Changeset.t()}
  def call(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Key Points

- **File system enforces SRP** via one action per file
- **Domain API** delegates to action modules
- **Clear boundaries** via folder structure

## SRP in Domain Resource Action Pattern (Flexible)

### Pattern: Separate Action Modules

```elixir
# Option A: One module per action (elixir-scribe-like)
lib/my_app/accounts/user/
  ├── create.ex
  ├── update.ex
  └── delete.ex

# Option B: Multiple actions per module (flexible)
lib/my_app/accounts/user.ex
  # All actions in one module, separated by functions
```

### Key Points

- **Flexibility** allows team to choose SRP enforcement level
- **Standard ai-rules** provides Domain Resource Action pattern foundation
- **Consistency** matters more than specific pattern

## Best Practices

### All Approaches

1. **Clear purpose**: Each module/action has single, documented purpose
2. **Separate concerns**: External services delegated, not mixed in
3. **Delegation**: Domain APIs delegate to action implementations
4. **Documentation**: Explain SRP in @moduledoc
5. **Testing**: Unit test each responsibility independently

### Implementation Checklist

- [ ] Purpose clearly defined
- [ ] Boundaries respected (no cross-cutting concerns in module)
- [ ] External services delegated
- [ ] Domain API provides clean contract
- [ ] Changesets handle validation (Ash) or manual (elixir-scribe)
- [ ] Tests cover each responsibility

## Integration with ai-rules

### When to Use

- **Architect**: Choose SRP enforcement level for project
- **Orchestrator**: Implement within chosen structure
- **Reviewer**: Verify SRP compliance across codebase
- **Backend Specialist**: Implement Domain Resource Action pattern
- **QA**: Test each responsibility independently

### Key Resources

- `skills/elixir-scribe/SKILL.md`: elixir-scribe patterns
- `skills/api-design/SKILL.md`: Ash code interfaces
- `docs/ash_vs_elixir_scribe.md`: Detailed comparison
- `patterns/architecture_decision_matrix.md`: Decision framework

---

## Summary

**Key Takeaway**: All three approaches (Ash, elixir-scribe, flexible) implement SRP. The choice depends on:
1. Project type (Phoenix web vs Nures vs vanilla)
2. Team composition (size, Ash experience)
3. Constraints (existing codebase, timeline)
4. Philosophy (manual discipline vs framework guidance)

**Recommendation**: Use decision matrix and document choice in `project_requirements.md`.
