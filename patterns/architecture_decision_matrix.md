# Architecture Decision Matrix

**Purpose**: Quick reference for choosing between Ash Framework and elixir-scribe approaches.

## Decision Tree

### Question 1: What type of project?

```bash
[ ] Phoenix web application (likely Ash)
[ ] Nures embedded system (likely elixir-scribe)
[ ] Vanilla Elixir service (evaluate both)
[ ] Library/SDK (evaluate team preference)
```

**Decision Flow**:
- **Phoenix web** → Go to Q2
- **Nures embedded** → Use elixir-scribe
- **Vanilla Elixir** → Go to Q3
- **Library/SDK** → Go to Q4

---

### Question 2 (Phoenix web): Team experience with Ash?

```bash
[ ] Senior team with Ash experience
[ ] Mixed experience, some Ash exposure
[ ] Junior team, no Ash experience
```

**Decision Flow**:
- **Senior Ash** → Use Ash Framework
- **Mixed** → Evaluate Ash vs elixir-scribe based on other criteria
- **Junior** → Consider elixir-scribe for learning, Ash for long-term

---

### Question 3 (Vanilla Elixir): Team size and preferences?

```bash
[ ] Small team (< 5 developers)
[ ] Large team (5+ developers)
[ ] Team prefers explicit structure
[ ] Team prefers code generation
```

**Decision Flow**:
- **Small + explicit** → Use elixir-scribe
- **Large + generation** → Consider Ash Framework
- **Mixed preferences** → Evaluate team consensus

---

### Question 4 (Library): Target use case?

```bash
[ ] Framework for end users
[ ] Low-level library
[ ] Tool/SDK for other developers
```

**Decision Flow**:
- **Framework** → Consider Ash for declarative resources
- **Library/SDK** → Consider elixir-scribe for explicit APIs
- **Low-level** → Consider Domain Resource Action pattern

---

## Quick Reference

| Criteria | elixir-scribe | Ash Framework | Notes |
|-----------|----------------|----------------|-------|
| **Learning curve** | ⚠️ Steeper (new pattern) | ✅ Familiar (Elixir) | elixir-scribe: Teams learning, Ash: Experienced benefit |
| **Team size** | ✅ Small teams preferred | ✅ Any size | elixir-scribe: Manual coordination, Ash: Framework support |
| **Code generation** | ❌ None | ✅ Excellent | Ash: Major productivity boost |
| **Self-documenting** | ✅ High (folders) | ⚠️ Medium (need docs) | elixir-scribe: Immediate, Ash: Auto-generated |
| **Flexibility** | ✅ Highest (no framework) | ⚠️ Framework opinionated | elixir-scribe: Any pattern, Ash: Declarative |
| **Framework** | None required | ⚠️ Requires Ash | elixir-scribe: Framework-agnostic, Ash: Opinionated |
| **Type safety** | ✅ Dialyzer | ✅ Ash typespecs | Both: Strong typing |
| **Community** | Emerging | Established | elixir-scribe: New pattern, Ash: Strong momentum |

---

## Decision Steps

1. Assess project type (web, embedded, vanilla, library)
2. Evaluate team composition (size, experience, preferences)
3. Consider constraints (existing codebase, timeline, tooling)
4. Use matrix above for quick reference
5. Document decision in ADR or project requirements
6. Stay consistent within project/domain

---

## Integration with ai-rules

Use this matrix with:
- `skills/elixir-scribe/SKILL.md` for detailed elixir-scribe patterns
- `skills/api-design/SKILL.md` for Ash Framework patterns
- `docs/ash_usage_rules.md` for Ash usage rules
- `docs/ash_vs_elixir_scribe.md` for detailed comparison
- `roles/architect.md` for framework decision guidance

---

## Examples

### Phoenix Web with Ash

```elixir
# Ash resources + LiveView
defmodule MyAppWeb do
  use Phoenix.LiveView
  alias MyApp.Blog

  def handle_params(%{"id" => id}, socket) do
    post = MyApp.Blog.get_post!(id, load: [:author, :comments])
  {:noreply, socket}
  end
end
```

### Nures Embedded with elixir-scribe

```bash
# Explicit folder structure
lib/my_nerves_app/
  └── domains/
      └── hardware/
          └── motor/
              ├── create.ex
              ├── stop.ex
              └── api.ex
```

### Vanilla Elixir Service with elixir-scribe

```elixir
# Self-documenting folder structure
lib/my_service/
  └── domains/
      └── payments/
          ├── process.ex
          ├── refund.ex
          └── api.ex
```
