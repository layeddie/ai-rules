## Context
- Date: 2026-02-11
- Target repo: `ai_rules_agent` (companion runtime)
- Goal: Introduce production-credible memory/retrieval options using `memento` and `arcana` with minimal API breakage.
- Constraint: Ignore `que` for this phase.

## Branch
- Planning branch in this repo: `codex/memento-arcana-implementation-plans`
- Expected execution branch in agent repo tomorrow: `codex/memento-arcana-runtime`

## Current-State Audit (from `ai_rules_agent`)
- Existing memory behaviour is pluggable (`AiRulesAgent.Memory` with `load/1`, `store/2`).
- Existing backends: `Memory.File`, `Memory.SQLite`, `Memory.Log`.
- Existing RAG index is ETS-only (`AiRulesAgent.RAG.MemoryIndex`) and marked non-production.
- API start payload already accepts memory selector (`file`/`sqlite`).

## Plan
1. Add Memento-backed memory adapter
- Add optional dependency: `{:memento, "~> 0.5", optional: true}`.
- Create `AiRulesAgent.Memory.Memento` implementing `AiRulesAgent.Memory`.
- Storage model (v1): one record per `memory_id` containing serialized history for compatibility with current behaviour.
- API integration: allow `"memory": "memento"` in `AiRulesAgent.API.maybe_memory/1`.

2. Add Mnesia/Memento lifecycle management
- Add init/setup module for schema/table creation with explicit idempotent functions.
- Add config docs for mnesia dir and node naming.
- Add safe fallback: if memento not available, return actionable error and keep existing backends functional.

3. Add optional Arcana retrieval adapter
- Introduce retrieval behaviour for RAG index abstraction (e.g., `AiRulesAgent.RAG.Store`).
- Keep current ETS `MemoryIndex` as default implementation.
- Add optional Arcana adapter module for ingest/search when Arcana + Ecto repo are configured.
- Avoid hard dependency by feature flag and runtime checks.

4. Telemetry and observability
- Emit unified events from memory and retrieval boundaries.
- When Arcana is enabled, forward/bridge Arcana telemetry metadata into agent-level traces.

5. Tests
- Unit tests: Memory.Memento load/store roundtrip and restart behavior.
- Integration tests: API selects `memento` backend correctly.
- Contract tests: all memory backends satisfy shared memory behaviour.
- Optional adapter tests for Arcana behind feature flag.

6. Migration and rollout
- Default remains current backend behavior (no breaking change).
- New backends are opt-in via API/config.
- Document rollback: switch memory selector back to `file`/`sqlite`.

## Shared Functionality with `ai-rules`
- Shared architecture model:
  - Coordination memory: ETS/Mnesia (Memento)
  - Retrieval layer: Arcana (optional)
  - Durable audit: existing file/sqlite/postgres options
- Reuse exact terminology in both repos to reduce operator confusion.

## Deliverables
- `Memory.Memento` backend + API selector.
- RAG store abstraction + optional Arcana adapter.
- Tests and migration notes.

## Risks
- Mnesia table lifecycle mistakes (startup race conditions).
- Optional dependency complexity around Arcana/Ecto boot ordering.

## Next-Step Implementation Order (tomorrow)
1. Memory.Memento + tests
2. API wiring + config docs
3. RAG store abstraction
4. Arcana adapter + guarded integration tests
