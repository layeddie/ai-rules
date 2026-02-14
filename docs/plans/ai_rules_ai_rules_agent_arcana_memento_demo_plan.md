## Context
- Date: 2026-02-12
- Repo: `/Users/elay14/projects/2026/ai-rules`
- Goal: define a concrete test/demo project showing `ai-rules` and `ai_rules_agent` working together with:
  - Arcana for local documentation retrieval via `pgvector`
  - Memento/Mnesia for local agent working memory during project development

## Why This Demo
This demo should prove the product direction in a hands-on way:
- local-first Elixir developer agent workflows,
- reduced remote/MCP token overhead for routine operations,
- practical integration between policy layer (`ai-rules`) and runtime layer (`ai_rules_agent`).

## Target Outcome
A small Elixir/Phoenix test project where an agent can:
1. retrieve relevant local docs from Arcana (`pgvector`),
2. keep short-term working state in Mnesia (via Memento),
3. generate/apply code patches safely,
4. run local tests and report outcomes.

## Demo Architecture (v1)
- Policy layer: `ai-rules`
  - roles/skills/prompts/guardrails
- Runtime layer: `ai_rules_agent`
  - lifecycle endpoints (stdio or HTTP)
  - tool orchestration and patch/test flow
- Retrieval layer: Arcana
  - ingest local Elixir/Phoenix docs + selected project docs
  - semantic search exposed as tool
- Working memory layer: Memento
  - per-session/per-task memory state in Mnesia
- Durable artifacts (optional in v1)
  - file logs for run summaries and outputs

## Scope (Must-Have)
1. Demo project skeleton
- Add a dedicated demo folder (or expand existing `test_project`) with clear setup instructions.
- Include minimal domain code with tests that can be modified by agent tasks.

2. Arcana integration
- Configure Arcana with project repo and `pgvector`.
- Add ingestion script/task for local docs (Elixir guides + project docs).
- Add retrieval tool in `ai_rules_agent` (e.g., `docs_search`) using Arcana search.

3. Memento integration
- Add `Memory.Memento` backend in `ai_rules_agent` and wire selector.
- Configure local mnesia directory per env/node.
- Store agent conversation/working context by `memory_id`.

4. End-to-end demo flows
- Flow A: "Explain and fix failing test" using docs retrieval + local memory.
- Flow B: "Implement small feature from local docs" with patch + test execution.

5. Measurement
- Record per-run:
  - steps executed locally,
  - approximate tokens sent to model,
  - runtime latency.
- Provide a simple comparison narrative vs remote/MCP-heavy loop.

## Out of Scope (v1)
- broad multi-agent orchestration,
- distributed clustering,
- production hardening for all failure modes,
- full benchmark suite.

## Deliverables
- Demo project with reproducible setup.
- Arcana ingest/search wiring.
- Memento memory backend usage in runtime.
- Scripted demo scenarios and expected outputs.
- Short report: what worked, what failed, where token savings appeared.

## Implementation Sequence
1. Preflight and environment
- Verify Postgres + pgvector availability.
- Verify Mnesia/Memento local path setup.

2. Runtime integration
- complete `Memory.Memento` in `ai_rules_agent`.
- add Arcana retrieval tool adapter.

3. Demo project wiring
- expose tool config and memory selector in lifecycle start payload.
- add scripts/tasks for docs ingest and scenario runs.

4. Scenario implementation
- create 2 deterministic tasks with pass/fail criteria.

5. Validation and write-up
- run scenarios,
- capture metrics,
- summarize outcomes and next changes.

## Success Criteria
Demo is successful if:
- setup is repeatable on local machine,
- agent reliably uses Arcana for doc retrieval,
- agent state persists during runs via Memento,
- at least one code-change scenario completes with tests passing,
- report clearly shows local-first workflow benefits.

## Risks
- Arcana ingestion quality may vary with chunking/embedding settings.
- Mnesia schema/table initialization order issues may cause flaky startup.
- Measuring token savings precisely may require lightweight instrumentation additions.

## Next Step
After Arcana + Memento core integration lands, implement this demo immediately before expanding scope.
