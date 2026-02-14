## Context

- Date: 2026-02-13
- Repo: `/Users/elay14/projects/2026/ai-rules`
- Objective: merge high-value guidance from `sagents` AGENTS into `ai-rules/AGENTS.md` while keeping token usage low and tool-agnostic.

## Inputs Reviewed

- Current file: `AGENTS.md` (42 lines, highly compact, OpenCode-centric)
- Historical `ai-rules` versions in git:
  - `438f758` (~563 lines)
  - `f516200` (~561 lines)
  - `8616209` (~694 lines)
  - `3d9fb35` (~689 lines)
  - `83dfd11` (current slim version)
- External reference: `sagents` `AGENTS.md` (~356 lines)

## Constraints

1. Keep core `AGENTS.md` token-efficient (target 90-140 lines).
2. Keep core file tool/IDE-agnostic.
3. Move tool-specific details (OpenCode) out of core and into `tools/opencode/` docs.
4. Avoid duplicating content that already lives in `roles/`, `skills/`, or `docs/`.

## Proposed Structure for New `AGENTS.md` (token-optimized)

1. Purpose + precedence (5-8 lines)

- What this file is for.
- Rule precedence (`project_requirements.md`, repo-specific constraints, then shared guidance).

2. Universal workflow (8-14 lines)

- Plan / Build / Review lifecycle in tool-neutral wording.
- "Use your tool's equivalent configs/agents" language.

3. Minimal command checklist (8-12 lines)

- `mix deps.get`, `mix format`, `mix credo --strict`, `mix test`, optional `mix dialyzer`.
- Short guidance for targeted test runs and troubleshooting.

4. High-impact guardrails (15-25 lines)

- No secrets, no unsafe shell actions, no destructive git.
- OTP, N+1, testing, and error tuple conventions.
- Req preferred for HTTP in Elixir projects.

5. Task-to-doc routing index (15-25 lines)

- One-line pointers to:
- - /Users/elay14/projects/2026/ai-rules/skills/html-css - this file already exists and follows my Jason Knight philosphy first when practical.
  - `roles/*.md`
  - `skills/*.md`
  - `docs/quickstart-agents.md`
  - `tools/*/README.md`
- Keep as map, not explanations.

6. Tool-specific policy pointer (3-5 lines)

- Core is tool-agnostic.
- OpenCode details: `tools/opencode/README.md`.
- Claude details: `tools/claude/README.md`.
- Cursor details: `tools/cursor/README.md`.

## What to Pull from `sagents` (significant + low-token)

1. Keep

- clear "common development commands" block.
- explicit test-cost warnings (live/billable calls pattern, adapted to your stack).
- short, high-value Elixir guardrails (immutability rebinding, no `String.to_atom` from user input, struct access rules).
- concise test reliability guidance (`start_supervised!`, avoid sleep-based sync).

2. Adapt (do not copy verbatim)

- architecture explanation -> map to ai-rules concepts (roles/skills/modes), not sagents internals.
- framework-specific sections (Phoenix/Tailwind UI rules) -> only if they match ai-rules scope.

3. Exclude

- long framework boilerplate.
- content already fully covered in `roles/` and `skills/`.
- heavy examples better stored in pattern docs.

## Section-to-Section Merge Matrix

Legend:

- `Keep`: move into new core `AGENTS.md` (condensed).
- `Adapt`: rewrite for ai-rules scope/tool-agnostic style.
- `Relocate`: move to another file and link from AGENTS.
- `Drop`: do not carry forward.

### Source: `sagents` AGENTS.md -> ai-rules destination

| Source section                          | Action   | Destination                                              | Token note                                                |
| --------------------------------------- | -------- | -------------------------------------------------------- | --------------------------------------------------------- |
| `Project Overview`                      | Adapt    | `AGENTS.md` intro (2-4 lines)                            | Keep only purpose + precedence                            |
| `Common Development Commands`           | Keep     | `AGENTS.md` checklist                                    | High signal, low tokens                                   |
| `Setup and Dependencies`                | Adapt    | `AGENTS.md` + `docs/quickstart-agents.md`                | Keep secrets warning; no project-specific env boilerplate |
| `Testing` (live/billable warnings)      | Keep     | `AGENTS.md` test guardrails                              | Useful cost control guidance                              |
| `Code Quality` (`mix precommit`)        | Adapt    | `AGENTS.md` + `README.md`                                | Use ai-rules quality command set                          |
| `High-Level Architecture`               | Drop     | N/A                                                      | Too repo-specific to sagents internals                    |
| `Testing Guidelines`                    | Keep     | `AGENTS.md` concise rules                                | Retain structure-mirroring and sync/async caution         |
| `Important Notes`                       | Adapt    | `AGENTS.md` guardrails                                   | Keep API key and cost cautions                            |
| `Project guidelines` (`Req` preference) | Keep     | `AGENTS.md` guardrails                                   | High-value Elixir standard                                |
| `Phoenix v1.8 guidelines`               | Relocate | `skills/liveview-patterns` or dedicated Phoenix skill    | Too detailed for core AGENTS                              |
| `JS and CSS guidelines`                 | Relocate | `skills/html-css`                                        | UI stack-specific; keep out of core                       |
| `UI/UX guidelines`                      | Relocate | `skills/html-css`                                        | Not AGENTS core                                           |
| `Elixir guidelines`                     | Keep     | `AGENTS.md` short rule list                              | Keep only top 8-12 rules                                  |
| `Mix guidelines`                        | Keep     | `AGENTS.md` short rule list                              | High-value and brief                                      |
| `Test guidelines`                       | Keep     | `AGENTS.md` short rule list                              | Keep `start_supervised!` and no sleep-sync                |
| `usage_rules` sections                  | Relocate | `docs/usage_rules_integration.md` + short AGENTS pointer | Keep AGENTS pointer only                                  |

### Source: `ai-rules` historical `3d9fb35` -> ai-rules destination

| Source section                                   | Action                  | Destination                                                  | Token note                          |
| ------------------------------------------------ | ----------------------- | ------------------------------------------------------------ | ----------------------------------- |
| `Overview`                                       | Adapt                   | `AGENTS.md` intro                                            | Remove OpenCode-first wording       |
| `Agent Responsibilities`                         | Keep                    | `AGENTS.md` responsibilities (condensed)                     | Keep as short numbered list         |
| `OpenCode Modes` (Plan/Build/Review details)     | Relocate                | `tools/opencode/README.md`                                   | Keep AGENTS tool-neutral            |
| `Tool Usage Guidelines` (mgrep/serena/grep/bash) | Relocate                | `tools/opencode/README.md` + `docs/mixed-search-strategy.md` | AGENTS keeps 1-line routing pointer |
| `Agent Roles Integration`                        | Keep                    | `AGENTS.md` routing index                                    | Keep one-line role pointers only    |
| `Quality Standards`                              | Keep                    | `AGENTS.md` guardrails                                       | Compact bullets only                |
| `Common Patterns` with code blocks               | Relocate                | `patterns/*` and role/skill docs                             | Remove examples from AGENTS         |
| `Troubleshooting`                                | Relocate                | `docs/quickstart-agents.md` + tool docs                      | Keep AGENTS minimal                 |
| `Integration with Other Tools`                   | Adapt                   | `AGENTS.md` tool-agnostic pointer + `tools/README.md`        | Avoid primary-tool bias             |
| Persona content (historically in AGENTS)         | Relocate (already done) | `roles/beamai.md`                                            | Keep AGENTS pointer only            |

### Disclaimer Placement Matrix

| Disclaimer type                                            | Recommended file            | Reason                            |
| ---------------------------------------------------------- | --------------------------- | --------------------------------- |
| Short operational disclaimer (scope + precedence + safety) | `AGENTS.md` top (2-4 lines) | Needed at instruction entry point |
| Long product positioning/tool philosophy                   | `README.md`                 | Better for onboarding narrative   |
| Tool-specific caveats and constraints                      | `tools/*/README.md`         | Avoid core AGENTS bloat           |

## Deep-Dive File Pass Needed (before editing)

1. Core docs

- `AGENTS.md`
- `docs/quickstart-agents.md`
- `README.md` (top-level positioning)

2. Tool docs

- `tools/README.md`
- `tools/claude/README.md`
- `tools/cursor/README.md`
- create/fix `tools/opencode/README.md` and align references

3. Role/skill overlap check

- `roles/architect.md`, `roles/orchestrator.md`, `roles/reviewer.md`
- `skills/README.md` and key skills (`otp-patterns`, `ecto-query-analysis`, `test-generation`, `elixir-guidelines`)

## Execution Plan

1. Inventory and map (no edits)

- Build a matrix: current AGENTS lines -> destination file (`AGENTS`, `tools/*`, `roles/*`, `skills/*`).
- Mark duplicates and stale sections.

2. Draft new tool-agnostic AGENTS

- Keep only high-value routing + guardrails + checklist.
- Keep token budget under 140 lines.

3. Relocate OpenCode specifics

- Add OpenCode operational detail into `tools/opencode/README.md`.
- Remove OpenCode-specific mode file paths from core AGENTS.

4. Link, don’t repeat

- Replace prose blocks with short pointers to roles/skills/docs.
- Keep each pointer one line.

5. Validate

- Confirm no broken references.
- Confirm AGENTS mentions all supported tools neutrally.
- Confirm top-level token budget target.

## Licensing / Copyright Considerations

- `sagents` is Apache-2.0 licensed (copyright Mark Ericksen).
- You can reuse/adapt content, but safest approach is:
  1. Prefer paraphrase and structural borrowing over verbatim copy.
  2. If reusing distinctive text, include attribution note in commit message and optionally in docs comments.
  3. Preserve any required license headers if copying substantial portions verbatim.
- Practical recommendation: do not copy large blocks verbatim; rewrite in ai-rules voice and keep references.

## Suggested Deliverables

1. Updated `AGENTS.md` (tool-agnostic, token-optimized).
2. New/updated `tools/opencode/README.md` (OpenCode details moved out of core).
3. Short "AGENTS content map" in `docs/` for maintainers.

## Answers to Your Questions

1. Can we see earlier AGENTS versions in git history?

- Yes. Significant prior versions are present (563-694 lines) and can be used to restore high-value sections.

2. Any licensing concerns?

- Low risk if we paraphrase.
- Apache-2.0 allows reuse with conditions; avoid large verbatim copy without attribution.
