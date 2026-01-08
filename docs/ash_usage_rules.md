# Ash Framework Usage Rules Reference

**Source**: https://github.com/ash-project/ash/blob/main/usage-rules.md (1,269 lines)
**Extracted by**: Key pattern extraction (recommended approach)
**Last Updated**: 2026-01-08

## Purpose

This document provides a curated reference to Ash Framework's official usage-rules.md, focusing on key patterns that complement ai-rules guidelines.

## When to Use

### Use This Reference When
- Designing Ash resources for new features
- Reviewing Ash-based code
- Choosing between Elixir idioms and Ash patterns
- Implementing Ash code interfaces
- Working with Ash policies and authorizations

### Use Ash SKILL.md When
- Need comprehensive Ash patterns with examples
- Understanding Ash DSL syntax and capabilities
- Learning Ash from scratch

---

## Code Interfaces

### Key Principles

1. **Define code interfaces on domains** - Create contract for calling into Ash resources
2. **Prefer primary read actions** - Use `get_by` when looking up by primary key or identity
3. **Use query option for filtering** - Pass filters, sorts, limits in `query:` parameter
4. **Pass additional inputs as map** - Use map parameter for actor, tenant, etc.
5. **Use code interfaces in LiveViews** - Never call `Ash.get!/2` directly in web modules

### Pattern: Define Code Interface

```elixir
# GOOD - Use code interface on domain
defmodule MyApp.Blog do
  use Ash.Domain

  resources do
    resource Post, do
      define :get_post, action: :read, get_by: [:id]
      define :list_posts, action: :read
      define :create_post, action: :create, args: [:title, :content]
      define :update_post, action: :update, args: [:title, :content]
    end
end

# Then call via domain API
post = MyApp.Blog.get_post!(post_id)
posts = MyApp.Blog.list_posts!(query: [filter: [published: true], limit: 10], load: [:author, :comments])
```

### Pattern: Pass Query Options

```elixir
# GOOD - Use query option
posts = MyApp.Blog.list_posts!(
  query: [
    filter: [status: :published],
    sort: [published_at: :desc],
    limit: 10
  ],
  load: [:author, :comments]
)
```

### Pattern: Pass Additional Inputs

```elixir
# GOOD - Pass actor via map
MyApp.Blog.create_post!(
  title,
  content,
  %{actor: current_user, tenant: tenant_id}
)
```

### ❌ BAD Patterns

```elixir
# BAD - Direct Ash calls in LiveView
def handle_params(%{"id" => id}, socket) do
  post = Ash.get!(MyApp.Blog.Post, id)  # NO!
  Ash.load!(post, [:author])  # NO!
end

# BAD - Manual query building
query = Ash.Query.filter(MyApp.Blog.Post, published == true)
Ash.read!(query)  # Use code interface instead
```

---

## Actions

### Key Principles

1. **Create specific, well-named actions** - Not generic CRUD
2. **Put business logic inside actions** - Use hooks (before_action, after_action)
3. **Use action arguments for inputs** - Validate user inputs properly
4. **Use preparations to modify queries** - Conditional query modifications
5. **Prefer domain code interfaces** - Call actions via domain API

### Pattern: Action with Hooks

```elixir
defmodule MyApp.Blog.Post do
  use Ash.Resource

  actions do
    create :create do
      accept [:title, :content]
      
      # Hook to add timestamps
      change Ash.Changeset.before_action(fn changeset, _context ->
        put_change(changeset, :published_at, DateTime.utc_now())
      end)
      
      # Hook to send notification after create
      change Ash.Changeset.after_action(fn changeset, _context ->
        MyApp.Notifier.send_post_created(changeset.data)
      end)
    end
  end
end
```

### Pattern: Use Action Arguments

```elixir
# GOOD - Action with arguments
actions do
  create :create do
    accept [:title, :content]
    
    validate fn changeset ->
      validate_required(changeset, [:title])
      validate_length(changeset, :title, max: 200)
      validate_format(changeset, :content, match: ~r/^[\w\s.,]{10,}/)
    end
  end
end

# BAD - Generic create without validation
actions do
  create :create do
    # No argument validation
  end
end
```

---

## Querying Data

### Key Principles

1. **Require Ash.Query** - Always use `require Ash.Query` when using `Ash.Query.filter`
2. **Use Ash.Query.filter** - Macro-based filtering with natural syntax
3. **Leverage code interfaces** - Prefer domain read actions over manual queries
4. **Preload associations efficiently** - Avoid N+1 queries
5. **Use preparations for conditional logic** - Don't filter in application code

### Pattern: Query with Filter

```elixir
# GOOD - Use Ash.Query
require Ash.Query

def list_published_posts do
  Ash.Query.filter(Post, published == true)
  |> Ash.Query.sort(published_at: :desc)
  |> Ash.Query.limit(10)
  |> Ash.read()
end
```

### Pattern: Domain Read Action

```elixir
# GOOD - Use code interface
def list_published_posts do
  MyApp.Blog.list_posts!(query: [filter: [published: true], limit: 10])
end
```

### ❌ BAD Pattern

```elixir
# BAD - Forgetting require Ash.Query
def list_published_posts do
  Ash.Query.filter(Post, published == true)  # ERROR: require missing
  |> Ash.read()
end
```

---

## Authorization Functions

### Key Principles

1. **Auto-generated authorization checks** - Ash generates `can_action?` and `can_action` functions
2. **Use for conditional rendering** - Show/hide UI elements based on permissions
3. **Check before action execution** - Verify user can perform action
4. **Use with Ash Scope** - Pass scope context for authorization
5. **Never authorize in frontend only** - Always check backend

### Pattern: Conditional Rendering

```elixir
# GOOD - Check before rendering
<.link>
  {if MyApp.Blog.can_update_post?(current_user, post_id), do
    <.button>Edit Post</.button>
  end}
</.link>
```

### Pattern: Authorization Check

```elixir
# GOOD - Use auto-generated function
def update_post(user_id, post_id, attrs) do
  case MyApp.Blog.can_update_post?(user_id, post_id) do
    true ->
      MyApp.Blog.update_post!(post_id, attrs, actor: user_id)
    {:error, reason} ->
      {:error, :unauthorized}
  end
end
```

---

## Decision Matrix

| Scenario | Primary Source | Secondary Source |
|----------|---------------|-----------------|
| **Designing Ash resources** | `docs/ash_usage_rules.md` | `skills/api-design/SKILL.md` |
| **Code interfaces** | `docs/ash_usage_rules.md` | `patterns/ash_code_interfaces.md` (to create) |
| **Action patterns** | `docs/ash_usage_rules.md` | `skills/api-design/SKILL.md` |
| **Query patterns** | `docs/ash_usage_rules.md` | `skills/ecto-query-analysis/SKILL.md` |
| **Authorization** | `docs/ash_usage_rules.md` | `roles/security-architect.md` |

**Rule of Thumb**:
- Use Ash patterns when working with Ash resources
- Fall back to general Elixir idioms for non-Ash code
- Reference Ash's official usage-rules.md for authoritative guidance
