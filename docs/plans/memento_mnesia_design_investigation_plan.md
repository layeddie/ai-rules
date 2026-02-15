## Memento/Mnesia Design Investigation (Pre-Implementation)

- Date: 2026-02-14
- Branch: `codex/memento-design-investigation`
- Status: Investigation only (no feature implementation yet)

## Objective
Decide whether and how `Memento`/`Mnesia` should be used for agent memory in `ai-rules`/`ai_rules_agent`.

## Scope
- In scope:
  - memory architecture options for local Elixir dev agents
  - Memento/Mnesia fit analysis (latency, reliability, complexity)
  - integration boundaries with Arcana (`pgvector`) and durable logs
  - comparison against commonly available memory MCP approaches
  - comparison of `usage_rules` vs Arcana for Elixir documentation retrieval
- Out of scope:
  - production rollout
  - broad distributed clustering design
  - full benchmark suite

## Terminology Guardrail
- `Memento` (Elixir wrapper) + `Mnesia` (Erlang DB) is the target stack.
- `Momento` (cloud product) is not the target technology.
- We may borrow architectural patterns, not implementation details, from Momento articles.

## Design Questions
1. What memory classes do we need?
- Working memory (per task/run)
- Session memory (short-lived, cross-step)
- Durable memory (audit/replay)

2. Which memory class should Mnesia own?
- Candidate: working + short session memory only

3. Where does Arcana fit?
- Candidate: semantic retrieval/recall only (not execution-state coordination)

4. What are failure boundaries?
- restart recovery
- schema/table initialization order
- memory growth controls

5. Memory MCP vs Memento/Mnesia: where is each best?
- MCP memory tools: broad interoperability and quick integration.
- Memento/Mnesia: low-latency local BEAM-native memory and transactional coordination.

6. Is Arcana worth it when `usage_rules` already keeps docs fresh?
- `usage_rules` as default source for package/library docs and updates.
- Arcana as optional layer for semantic retrieval across project-specific corpora.

## Candidate Architectures
### A. Mnesia-first hot memory + durable audit
- Mnesia/Memento: working/session state
- File/SQLite/Postgres: durable event log
- Arcana: retrieval for docs/context enrichment

### B. ETS hot cache + Mnesia checkpoint
- ETS for hottest path
- Mnesia periodic checkpointing
- Higher complexity, possibly lower latency

### C. Mnesia as single local memory store (short-term)
- simplest integration
- verify if this is sufficient before adding layered caching

### D. Arcana as optional sidecar (separate install, loosely coupled)
- Keep Arcana out of `ai-rules` and `ai_rules_agent` core dependencies.
- Run Arcana locally as separate service/project.
- Integrate through tool endpoint or IDE config wiring only.
- Preserve clean boundaries:
  - `ai-rules`: policy/guidance
  - `ai_rules_agent`: runtime/control plane
  - Arcana: optional retrieval service

## Investigation Tasks
1. Current-state audit (`ai_rules_agent`)
- map existing memory behavior and adapters
- map where retrieval hooks can be abstracted cleanly

2. Mnesia fit analysis
- table model options (one row per memory_id vs append log)
- transaction strategy and write frequency expectations
- storage path and environment configuration

3. Memory MCP vs Memento analysis
- evaluate tradeoffs: portability/interoperability vs local latency/control
- define where MCP memory should remain optional vs native memory backend

4. `usage_rules` vs Arcana boundary analysis
- define default policy: `usage_rules` first for Elixir/package docs
- define Arcana activation criteria for semantic/project-specific retrieval
- avoid duplication of documentation indexing responsibilities

5. Arcana separation model analysis
- define sidecar integration contract (tool endpoint/API boundary)
- keep Arcana local installation and lifecycle independent from core repos
- verify IDE/tool config wiring path (OpenCode/Codex/other local tool config)

6. Operational risk analysis
- startup ordering and idempotent table init
- data growth, compaction, TTL strategy
- backup/recovery expectations for local dev

7. Decision memo
- recommend architecture A/B/C/D
- include tradeoffs and reasons

## Lightweight Validation Plan (after design approval)
- micro tests:
  - read/write latency profile for expected agent loop calls
  - restart/load behavior for memory_id histories
  - bounded growth behavior under repeated interactions
- no feature expansion until these pass

## Deliverables
1. Design memo: `docs/plans/memento_mnesia_agent_memory_decision.md`
2. Integration contract sketch for `ai_rules_agent` memory/retrieval boundaries
3. Arcana sidecar integration note (separate install + local tool wiring)
4. Implementation sequence proposal (small, test-first increments)

## Exit Criteria (to start implementation)
- Architecture choice approved
- Memory ownership boundaries are explicit
- Arcana integration boundary is explicit
- Failure and growth controls defined

## Notes
- Local `pgvector` already exists on this machine; Arcana feasibility can be validated quickly once architecture is approved.
