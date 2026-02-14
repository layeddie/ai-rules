# AI Rules Agent Guide

Scope: this file is the compact, tool-agnostic operating guide for coding agents in this repo.
Precedence: explicit user/developer instructions > this file > linked role/skill/tool docs.
Safety: never expose secrets, never run destructive git/shell commands without explicit approval.

## Workflow (tool-agnostic)

1. Plan
- Read `project_requirements.md` and relevant docs.
- Map domain/resource/action boundaries before coding.
- Prefer read-only discovery first (`rg`, semantic search, docs).

2. Build
- Implement with small, testable changes.
- Keep APIs and process boundaries explicit.
- Keep framework/tool glue thin.

3. Review
- Check correctness first, then OTP/performance, then readability.
- Focus on actionable findings and missing tests.

## Common Commands

```bash
mix deps.get
mix format
mix credo --strict
mix test
# optional when configured:
mix dialyzer
```

Targeted test runs:

```bash
mix test test/path/to/file_test.exs
mix test test/path/to/file_test.exs:42
mix test --failed
mix test --include live_call
```

Before using unfamiliar tasks, check options with `mix help <task>`.

## High-Impact Guardrails

- Do not read or commit secret files (`.envrc`, `.env`, credentials).
- Confirm before running billable/live external API tests.
- Prefer `Req` for HTTP clients in Elixir projects.
- Use `{:ok, result}` / `{:error, reason}` tuples for fallible operations.
- Avoid exceptions for normal control flow.
- Do not use `String.to_atom/1` on user input.
- Rebind immutable values from `if/case/cond` results; do not rely on inner rebinding.
- Do not use map-access syntax (`struct[:field]`) on structs.
- Keep one module per file unless there is a deliberate, documented reason.
- For OTP work, ensure child specs are named where required (`DynamicSupervisor`, `Registry`).
- Prefer `Task.async_stream/3` with explicit timeout/back-pressure choices.
- Avoid N+1 queries; preload/index deliberately.

## Test Reliability Rules

- Mirror source structure in tests.
- Use `start_supervised!/1` for supervised process lifecycle in tests.
- Avoid sleep-based synchronization in tests.
- Prefer monitors/assertions (`Process.monitor`, `assert_receive`) over timing sleeps.
- Keep examples deterministic and local-first unless a live test is explicitly required.

## usage_rules (when available)

- If `usage_rules` is installed, consult docs early with `mix usage_rules.docs` and `mix usage_rules.search_docs`.

## Role + Skill Routing

- Default persona: `roles/beamai.md`
- Role deep dives: `roles/*.md`
- Skills index and specializations: `skills/README.md`, `skills/*/SKILL.md`
- Quickstart and command map: `docs/quickstart-agents.md`
- Search strategy: `docs/mixed-search-strategy.md`
- Ash/OTP/LiveView/Nerves references: `patterns/`

## Tool-Specific Docs

Core guidance is tool-neutral. Use tool docs for execution details:

- OpenCode: `tools/opencode/README.md`
- Claude: `tools/claude/README.md`
- Cursor: `tools/cursor/README.md`
- Shared tools index: `tools/README.md`

## Notes on Source Material

This guide is informed by internal history and community best practices (including `sagents` Apache-2.0 guidance), rewritten for this repo's scope and token efficiency.
