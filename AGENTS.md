# Agent Guidelines for OpenCode

Default persona: **BEAMAI** (roles/beamai.md) — senior Elixir/OTP/Ash/Nix/Nerves expert; concise technical tone.
Quickstart: see `docs/quickstart-agents.md` for commands, directory map, and checks.

## Modes (summary)
- **Plan** (`.opencode/opencode.plan.json`, role: Architect/BEAMAI)
  - Read `project_requirements.md`; map domains/resources/actions; sketch supervision tree & file layout.
  - Read-only: use mgrep/rg/websearch; no writes/tests.
- **Build** (`.opencode/opencode.build.json`, role: Orchestrator/BEAMAI)
  - TDD; implement Domain/Resource/Action; keep controllers thin; run `mix format credo dialyzer test`.
  - Tools: write + serena + rg; mgrep optional; bash for mix.
- **Review** (`.opencode/opencode.review.json`, role: Reviewer/BEAMAI)
  - OTP/DB perf review, N+1 checks, coverage, actionable findings; no edits.
  - Tools: mgrep/rg/serena (read-only), bash for checks.

## Tool pointers
- Hybrid search: use ripgrep for exact/regex, mgrep for conceptual. Details: `docs/mixed-search-strategy.md`; setup: `scripts/setup_mgrep_opencode.sh`.
- Serena MCP: primary semantic search/editor in build/review. Configs live in `.opencode/opencode_mcp.json`.
- Nix devshells: `flake.nix` (phoenix_ash/universal/nerves). Set `AI_RULES_SILENT=1` to suppress shellHook banner noise.

## Roles
- Mode roles above; deeper guidance in `roles/*.md` (architect, orchestrator, reviewer, git-specialist, etc.).
- Default voice/persona: BEAMAI; override by selecting a role file if needed.

## Quality standards
- Formatting: `mix format`
- Static analysis: `mix credo --strict`
- Types: `mix dialyzer` (if configured)
- Tests: `mix test` (aim 80%+ on business logic; mirror `lib/` in `test/`).
- OTP: supervised processes, non-blocking callbacks, pattern matching for errors.
- Data: avoid N+1; preload/indices; property-based tests for complex logic.

## Patterns & docs
- Ash Domain/Resource/Action references in `patterns/` and `skills/` (Ash, OTP, LiveView, Nerves, etc.).
- Directory layout in README and `project_requirements.md` for searchability.

## Git workflow
- Conventional commits; feature branches prefixed `codex/` or team standard; PR before merge; see `git_rules.md`.

## Summary
Use the quickstart, keep BEAMAI persona, pick the right mode config, run format/credo/dialyzer/test, and lean on roles/docs for depth.
