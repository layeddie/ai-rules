## ai_rules_agent Clarity Audit Report

- Date: 2026-02-14
- Scope: read-only audit (no code edits)
- Target: `/Users/elay14/projects/2026/ai_rules_agent`
- Focus: moduledoc coverage, doc quality, doctest opportunities, API readability, deterministic examples, codeflow structure

## Executive Summary
`ai_rules_agent` is already structurally promising for AI/human readability: all modules have `@moduledoc`, the runtime model is understandable, and tests exist for core flows.

Primary gap is not missing modules; it is missing **function-level contract docs + doctests + clearer codeflow boundaries** in key entrypoint modules.

## Metrics Snapshot
- Modules in `lib/`: `30`
- Modules with `@moduledoc`: `30` (one is `@moduledoc false`)
- Public function `@doc` annotations: `6` (low)
- Doctest declarations found: `0`

Key files by surface area:
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/api.ex` (281 lines, 10 public defs, 0 `@doc`)
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_server.ex` (311 lines, 6 public defs, 3 `@doc`)
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_manager.ex` (105 lines, 5 public defs, 0 `@doc`)

## Prioritized Findings

### P1: Public API contract documentation is too thin on core modules
- Files:
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/api.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_manager.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/tools/file_search.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/rag/pgvector_store.ex`
- Risk:
  - AI agents and humans cannot quickly infer parameter contracts, return shapes, or failure semantics from function docs.
- Impact:
  - Increased misuses of lifecycle endpoints and tool contracts.

### P1: No doctest coverage for pure/deterministic modules
- Files with strong doctest potential:
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/tool_schema.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/rag/memory_index.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/error.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/test_helper.ex`
- Risk:
  - Documentation can drift from behavior; examples are not executable.

### P2: Entry-point modules combine multiple concerns
- Files:
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/api.ex`
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_server.ex`
- Observed concern mixing:
  - endpoint payload assembly + provider resolution + memory selection + allowlist logic + patch execution.
- Risk:
  - Harder to reason about codeflow and test in isolation.

### P2: Naming/semantics mismatch can confuse future readers
- File:
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/memory/sqlite.ex`
- Issue:
  - Named SQLite, but implementation is file-backed term storage with ETS cache.
- Risk:
  - Wrong operator expectations, especially for onboarding AI agents.

### P3: Contract docs on strategy/transport boundaries are uneven
- Files:
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/strategy.ex` (good behavior-level docs)
  - `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/transports/*.ex` (inconsistent `@doc` density)
- Risk:
  - Model/provider adapters become folklore instead of documented contracts.

## Out-of-the-Box Codeflow Proposal (Ash/Elixir-Scribe style influence)
Use "Domain -> Contract -> Implementation -> Test" flow for each subsystem:

1. Domain folders (already mostly present)
- `agent/`, `api/`, `memory/`, `rag/`, `tools/`, `transports/`, `strategies/`

2. Contract-first docs
- Each domain root module explains:
  - intent
  - public entrypoints
  - return/error conventions
  - deterministic examples

3. Thin entrypoint, thick pure modules
- Keep endpoint/runtime wiring thin.
- Push logic into small pure modules with doctests.

4. Test mirror by codeflow stage
- Unit tests for pure logic modules.
- Integration tests only at runtime boundaries.
- Add doctests as executable documentation for stable contracts.

This aligns with readability goals while preserving OTP runtime design.

## Suggested Patch Sequence (No implementation yet)

### Phase 1 (highest ROI, low risk)
1. Add `@doc` to all public functions in:
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/api.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_manager.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/rag/pgvector_store.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/tools/file_search.ex`

2. Introduce first doctest wave:
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/tool_schema.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/rag/memory_index.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/error.ex`

3. Add doctest runner modules under `test/` for those files.

### Phase 2 (codeflow clarity)
1. Extract API internals into focused modules (planned split only):
- provider resolution
- allowlist/policy checks
- patch execution
- doc lookup

2. Add high-level sequence docs to:
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/agent_server.ex`
- `/Users/elay14/projects/2026/ai_rules_agent/lib/ai_rules_agent/api.ex`

### Phase 3 (semantic consistency)
1. Resolve `Memory.SQLite` naming mismatch by either:
- renaming adapter to reflect file-backed behavior, or
- implementing real sqlite backend.

2. Standardize transport function docs and return shapes.

## Deterministic Doctest Rules for this repo
- Offline only (no network/API calls).
- No timing-sensitive assertions.
- Use deterministic inputs/outputs.
- Keep doctests on pure helpers and adapters with local behavior.

## Deliverable Status
- Prioritized clarity report: complete.
- Suggested patch sequence: complete.
- No `ai_rules_agent` code changes performed.
