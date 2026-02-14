## Context
- Date: 2026-02-12
- Repo: `/Users/elay14/projects/2026/ai-rules`
- Goal: clarify where `ai_rules_agent` should differentiate from Jido, and what it provides to `ai-rules`.
- Primary product intent: local agents for Elixir project development, with lower token cost than MCP-heavy workflows.

## Executive Positioning
`ai_rules_agent` should be positioned as a **local-first coding agent runtime for Elixir projects**, not as a general autonomous multi-agent framework.

- Jido: broad autonomous agent framework/runtime ecosystem.
- ai_rules_agent: practical developer-agent control plane focused on code workflows (read/patch/test/doc/tool calls) inside a project.

This is not a weakness. It is a deliberate product boundary.

## Why This Boundary Matters
Competing head-on with Jido on framework breadth will likely dilute focus and slow delivery.

Instead, `ai_rules_agent` should optimize for:
- low ceremony setup in real Elixir/Phoenix repos,
- predictable/safe code operations,
- local execution paths that reduce remote token overhead,
- first-class integration with `ai-rules` guidance and templates.

## What `ai_rules_agent` Offers `ai-rules`
`ai-rules` and `ai_rules_agent` are complementary layers:

- `ai-rules` provides:
  - agent instructions, roles, skills, templates, quality standards, workflow conventions.
- `ai_rules_agent` provides:
  - executable runtime surface to apply those rules locally:
    - HTTP/stdio lifecycle endpoints,
    - allowlisted file operations,
    - guarded patch application,
    - local test/doc lookup execution,
    - pluggable strategy/tool/memory runtime.

In short:
- `ai-rules` = policy, conventions, and guidance.
- `ai_rules_agent` = local execution engine that enforces and operationalizes those policies.

## Token-Cost Thesis (Core Value)
Initial idea: local agents to assist Elixir development while avoiding MCP protocol token expense.

That thesis is sound if we keep these priorities:
- Keep high-frequency operations local:
  - file search/read spans,
  - compile/test runs,
  - docs lookup and code navigation,
  - deterministic tool execution.
- Send only compact summaries/results to LLM calls.
- Avoid large, repeated MCP payload exchanges for routine repo operations.

Expected effect:
- lower token spend,
- lower latency for iterative workflows,
- better privacy and control for local codebases.

## Non-Goals (to Prevent Scope Creep)
`ai_rules_agent` should not become:
- a full generic multi-agent research framework,
- a full event-bus/signal-routing platform equivalent to Jido ecosystem breadth,
- a framework that requires complex orchestration primitives before delivering coding value.

## Recommended Product Statement
"`ai_rules_agent` is a local-first Elixir coding-agent runtime that turns `ai-rules` guidance into safe, executable developer workflows with low token overhead."

## Capability Map: Jido vs ai_rules_agent
- Jido strengths:
  - rich agent runtime ecosystem,
  - signals/routing/directives/plugins/sensors,
  - broad autonomous workflow composition.
- ai_rules_agent strengths:
  - repository-centric coding operations,
  - safety controls for file/patch/test,
  - local lifecycle interfaces (HTTP/stdio),
  - direct alignment with `ai-rules` roles/skills/templates.

They can coexist:
- Use Jido when you need a general autonomous agent platform.
- Use ai_rules_agent when you need a practical local coding-agent runtime for Elixir project delivery.

## 90-Day Differentiation Focus (Suggested)
1. Double down on local coding workflow primitives
- stronger patch safety checks,
- better failure diagnostics for test/compile loops,
- stable tool contracts and schema validation.

2. Tight ai-rules integration
- native loading of role/skill prompts,
- policy-aware action gating,
- quality-check hooks aligned to project standards.

3. Memory and retrieval pragmatism
- optional Memento-backed short-term memory,
- optional Arcana-backed retrieval,
- sane defaults that work without heavy infra.

4. Cost/latency observability
- per-request token estimate and local-work ratio,
- show savings from local execution over remote-heavy paths.

## Success Criteria
`ai_rules_agent` is successful if teams can:
- onboard in minutes,
- run useful local coding agents safely,
- reduce token/latency costs versus MCP-heavy patterns,
- ship Elixir/Phoenix changes faster with reproducible workflows.

## Decision
Proceed with focused positioning:
- Do not compete with Jido on breadth.
- Compete on local developer productivity, safety, and cost efficiency for Elixir coding workflows.
