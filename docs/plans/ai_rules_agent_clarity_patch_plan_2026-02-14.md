## ai_rules_agent Clarity Patch Plan

- Date: 2026-02-14
- Depends on: `/Users/elay14/projects/2026/ai-rules/docs/plans/ai_rules_agent_clarity_audit_report_2026-02-14.md`
- Goal: improve AI/human readability and testability without altering runtime behavior in early phases.

## Phase Plan

### Phase 1: Contract Documentation + Initial Doctests
1. Public `@doc` pass:
- `api.ex`, `agent_manager.ex`, `pgvector_store.ex`, `file_search.ex`

2. Doctest wave 1 (pure modules):
- `tool_schema.ex`
- `memory_index.ex`
- `error.ex`

3. Add doctest test files and run:
- `mix test`

Exit criteria:
- Public entrypoints in phase files have docs.
- At least 3 modules have passing doctests.

### Phase 2: Codeflow Decomposition (Readability-first Refactor)
1. Split `API` helper concerns into focused modules:
- provider resolver
- allowlist policy
- patch executor
- docs lookup

2. Keep external API stable.

3. Add module-level flow docs and deterministic examples.

Exit criteria:
- `api.ex` reduced in cognitive load.
- Tests unchanged in behavior.

### Phase 3: Semantic Consistency + Naming
1. Address `Memory.SQLite` semantics mismatch (rename or true sqlite implementation).
2. Standardize transport docs and return contract notes.

Exit criteria:
- Naming reflects behavior.
- Transport docs are consistent.

## Quality Gates (each phase)
- `mix format`
- `mix credo --strict`
- `mix test`
- Optional: `mix dialyzer` if configured

## Branching Sequence
1. `codex/ai-rules-agent-clarity-phase1-docs-doctests`
2. `codex/ai-rules-agent-clarity-phase2-api-flow`
3. `codex/ai-rules-agent-clarity-phase3-semantic-consistency`

## Notes
- Keep doctests local/offline only.
- Use explicit `iex>` examples in doctests.
- Keep behavior changes out of phase 1 unless required for correctness.
