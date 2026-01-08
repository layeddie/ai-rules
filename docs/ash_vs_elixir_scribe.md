# Ash Framework vs elixir-scribe

**Purpose**: Comprehensive comparison and decision framework for choosing between Ash Framework and elixir-scribe approaches.

**Last Updated**: 2026-01-08

## Philosophical Alignment

Both approaches aim for Single Responsibility Principle but enforce it differently:

### elixir-scribe Philosophy

**Core Values**:
- **Explicit over implicit**: File structure makes organization visible
- **Manual discipline**: Developer maintains structure via file naming
- **Code over configuration**: Prefer explicit code over DSL/magic
- **Anti-magic**: No hidden code generation or macros

**Enforcement**:
- **File system**: One action per file enforces SRP
- **Visual**: Structure immediately visible in file explorer
- **Manual**: Developer must follow pattern, no framework enforcement

### Ash Framework Philosophy

**Core Values**:
- **Declarative over imperative**: DSL describes what, not how
- **Framework guidance**: Patterns and conventions enforced by compiler
- **Type safety**: Strong typing and changesets via Ash
- **Code generation**: Automatic APIs and migrations reduce boilerplate

**Enforcement**:
- **DSL macros**: Compiler-level enforcement via resource DSL
- **Framework**: Ash provides patterns and tooling
- **Automatic**: Code generation enforces conventions

### Key Insight

**Both approaches aim for same goal** - Clear domain boundaries with Single Responsibility - but achieve it through:
- **elixir-scribe**: Manual file system discipline
- **Ash**: Framework-driven declarative code generation

---

## Feature Comparison Matrix

| Feature | elixir-scribe | Ash Framework | Notes |
|-----------|----------------|----------------|-------|
| **Folder structure** | ✅ Explicit files per action | ⚠️ DSL-derived (implicit) | elixir-scribe: Self-documenting, Ash: Code generation |
| **Action files** | ✅ One action = one module file | ⚠️ Actions defined in DSL | elixir-scribe: Manual SRP, Ash: Type-safe |
| **Domain APIs** | ✅ Explicit API modules | ✅ Code interfaces | Both: Clean contracts, different implementation |
| **Validation** | ✅ Ecto changesets | ✅ Ash changesets (enhanced) | Both: Type-safe validation |
| **Querying** | ✅ Manual Ecto | ✅ Ash.Query (natural syntax) | Ash: Declarative, elixir-scribe: Imperative |
| **Policies** | ❌ Manual | ✅ Ash.Policy (declarative) | Ash: Built-in authorization |
| **Code generation** | ❌ Manual | ✅ Automatic APIs/migrations | Ash: Major productivity boost |
| **Documentation** | ✅ Manual @moduledoc | ✅ Auto-generated from DSL | Both: Well-documented |
| **Learning curve** | ⚠️ Steeper (new pattern) | ✅ Familiar (Elixir) | elixir-scribe: Teams learning, Ash: Experienced benefit |
| **Framework** | None required | ⚠️ Requires Ash adoption | elixir-scribe: Framework-agnostic, Ash: Opinionated |
| **Type safety** | ✅ Dialyzer | ✅ Ash typespecs | Both: Strong typing available |
| **Community** | Growing | Strong momentum | elixir-scribe: Emerging, Ash: Established |

---

## Decision Framework

### Step 1: Assess Project Type

```bash
# What type of project are you building?
[ ] Phoenix web application (likely Ash)
[ ] Nerves embedded system (likely elixir-scribe)
[ ] Vanilla Elixir service (evaluate both)
[ ] Library/SDK (evaluate team preference)
```

### Step 2: Evaluate Team

```bash
# What is your team composition?
[ ] Small team (< 5 developers), some Ash experience
[ ] Mixed experience, some Ash knowledge
[ ] Junior team, no Ash experience
[ ] Senior team, strong Ash expertise
```

### Step 3: Consider Constraints

```bash
# What constraints exist?
[ ] Existing codebase is non-Ash (prefer elixir-scribe)
[ ] Ash framework already in use (prefer Ash)
[ ] Framework-agnostic needed (prefer elixir-scribe)
[ ] Timeline tight (prefer Ash for speed)
[ ] Learning time available (prefer elixir-scribe)
```

### Step 4: Choose Approach

Based on assessment, use this matrix:

| Project Type | Team | Recommended Approach | Primary Reason |
|-------------|-------|--------------------|---------------|
| **Phoenix web** | Senior/Mixed | Ash Framework | Built-in LiveView, authorization |
| **Phoenix web** | Junior | Ash Framework | Productivity boost, patterns |
| **Phoenix web** | Junior | elixir-scribe | Learning with explicit structure |
| **Nures embedded** | Any | elixir-scribe | No framework overhead |
| **Nures embedded** | Any | Ash Framework | Complex for embedded |
| **Vanilla Elixir** | Small | elixir-scribe | Simple, no framework |
| **Vanilla Elixir** | Large | Ash Framework | Code generation, scaling |
| **Library/SDK** | Experienced | Ash Framework | Consistent patterns |
| **Library/SDK** | Experienced | elixir-scribe | Framework-agnostic |

---

## Migration Strategy

### From elixir-scribe to Ash

```elixir
# Gradually migrate to Ash
1. Add Ash to deps
2. Generate Ash resources: mix ash.gen.resource
3. Keep elixir-scribe folder structure as domain API layer
4. Use Ash DSL for new features
5. Migrate elixir-scribe actions to Ash actions over time
```

### From Ash to elixir-scribe

```elixir
# Rare case - Ash overkill
1. Keep Ash resources for complex domains
2. Use elixir-scribe for simple, framework-agnostic services
3. Maintain clear boundary between approaches
```

### Hybrid Approach (Advanced)

```elixir
# Use Ash for web/business domains
# Use elixir-scribe for embedded/hardware layer
# Clear boundary documentation in project requirements
```

---

## Best Practices When Choosing

### 1. Document Decision

```bash
# Create ADR (Architecture Decision Record)
echo "Decision: Framework choice
Approach: [Ash | elixir-scribe]
Rationale: [Reasons from matrix above]
Date: $(date +%Y-%m-%d)"
```

### 2. Stay Consistent

```elixir
# Don't mix approaches within same domain
# Choose one approach and apply consistently
```

### 3. Consider Project Requirements

```elixir
# Reference project_requirements.md
# Align framework choice with documented requirements
```

### 4. Re-evaluate Periodically

```elixir
# Review decision every 3-6 months
# Adjust if team, project, or ecosystem changes
```

---

## Integration with ai-rules

### When to Use

- Use `docs/ash_usage_rules.md` for Ash-specific patterns
- Use `skills/elixir-scribe/SKILL.md` for elixir-scribe guidance
- Use `patterns/architecture_decision_matrix.md` (from Phase 1, Task 5.2) for decision framework
- Document choice in `project_requirements.md`

### Roles to Reference

- **Architect**: Use this comparison for framework decisions
- **Orchestrator**: Follow chosen approach consistently
- **Backend Specialist**: Implement within chosen framework/structure
- **Reviewer**: Verify consistency across codebase

---

## Summary

**Key Takeaway**: Both elixir-scribe and Ash Framework are valid approaches to Single Responsibility Principle. The choice depends on:

1. Project type (Phoenix web vs Nures vs vanilla Elixir)
2. Team composition (size, Ash experience)
3. Constraints (existing codebase, timeline)
4. Philosophy (manual discipline vs framework guidance)

**Recommendation**: Use decision framework to make informed, documented choice based on project needs.
