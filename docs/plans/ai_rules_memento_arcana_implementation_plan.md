## Context
- Date: 2026-02-11
- Repo: `/Users/elay14/projects/2026/ai-rules`
- Goal: Prepare `ai-rules` to support practical guidance for `memento` and `arcana` without regressing current tool-agnostic workflows.
- Constraint: Avoid duplicating Claude bridge skills/hooks added on 2026-02-10.

## Branch
- Working branch: `codex/memento-arcana-implementation-plans`

## Current-State Audit (already observed)
- Existing Claude bridge assets are present under:
  - `tools/claude/skills/{skill-discovery,ash-guardrails,ecto-query-analysis,liveview-lifecycle,otp-patterns}`
  - `tools/claude/hooks/hooks-settings.json`
  - mirrored templates under `templates/claude/...`
- Existing docs still contain Arcana removal framing:
  - `docs/migration_guide.md`
  - `docs/MCP_COMPARISON.md`

## Plan
1. Reframe Arcana guidance in docs (no implementation code yet)
- Replace hard "Arcana removed/domain mismatch" messaging with "optional RAG layer for agent memory/retrieval workloads".
- Keep clear boundary: Arcana is not required for core coding-agent workflows.
- Update comparison docs to show when Arcana is appropriate vs when Codicil/Probe/Serena are enough.

2. Add a shared architecture section for `ai-rules` + `ai_rules_agent`
- Define a common split:
  - Hot operational memory: ETS/Mnesia (via Memento)
  - Durable/audit memory: file/sqlite/postgres
  - Semantic retrieval: Arcana (optional)
- Document this as a reusable reference so both repos implement the same mental model.

3. Add integration playbooks (documentation-level)
- "Memento quickstart for agent state" playbook:
  - mnesia dir config
  - table lifecycle
  - transaction boundaries
- "Arcana quickstart for RAG memory" playbook:
  - repo requirements
  - ingestion/search workflow
  - telemetry hooks

4. Claude non-duplication guardrail
- Add an explicit matrix in docs/plans and/or Claude README:
  - Upstream `claude-code-elixir` skill names -> existing `ai-rules` skill equivalents.
- Rule: prefer mapping and links over copying entire skill packs when equivalent coverage already exists.

5. Validation checklist
- Ensure `README.md`, `docs/MCP_COMPARISON.md`, and `docs/migration_guide.md` are consistent.
- Ensure no duplicate skill directories are introduced under `tools/claude/skills`.
- Ensure template mirrors in `templates/claude/` remain one-to-one with `tools/claude/`.

## Deliverables
- Updated docs clarifying Arcana/Memento optional roles.
- A reusable shared architecture note referenced by both repos.
- A Claude capability mapping table that blocks duplicate-skill drift.

## Risks
- Mixed messaging if Arcana is described as both removed and recommended.
- Skill sprawl if upstream Claude skills are copied directly.

## Next-Step Implementation Order (tomorrow)
1. Docs consistency pass (Arcana framing)
2. Shared architecture doc section
3. Claude non-duplication mapping
4. Final README/quickstart alignment
