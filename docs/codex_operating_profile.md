# Codex Operating Profile (Short)

## Session Order

1. On new Codex app session: run `/Users/elay14/.local/bin/codex-fix-shell` and open a fresh terminal pane.
2. Clarity audit first (before feature work) when requested.
3. Plan in `docs/plans/`.
4. Implement on a dedicated `codex/*` branch.
5. Review (bugs/regressions/tests first).
6. Always check git status and decide whether to commit or stash changes.

## Working Rules

- Keep AGENTS/tooling guidance token-efficient.
- Prefer links over duplicated prose.
- Keep core AGENTS tool-agnostic; tool specifics in `tools/*`.
- Commit in small, meaningful chunks.

## Command Defaults

- Prefer `rg` for search.
- Run: `mix format`, `mix credo --strict`, `mix test` (and `mix dialyzer` if configured).
- Avoid destructive git actions unless explicitly requested.
- Codex shell bootstrap check: `echo $0` should show `zsh` in a new Codex terminal.

## Documentation Standards

- Public modules: `@moduledoc`.
- Public non-trivial functions: `@doc`.
- Doctests: local, deterministic, offline (no network).

## Skills

- External elixir skills can be found at https://skills.sh/?q=elixir

## Escalation Preference

- Approve safe recurring prefixes when stable (`git`, `mix`, `rg`).

## Improvement Loop

- Keep one source of truth in this file; do not create parallel Codex profile docs.
- Start each substantial request with:
  - `Goal`: single outcome in one sentence.
  - `Scope`: exact files/dirs allowed to change.
  - `Done When`: concrete acceptance checks (commands, docs, config updates).
  - `Constraints`: hard requirements/non-negotiables.
- For strategic/tooling decisions, require:
  - one recommended option,
  - rejected alternatives with short reasons,
  - explicit rollout/fallback plan.
- Before closeout, confirm:
  - requested files were updated,
  - checks were run (or clearly not run),
  - next action is explicit (none, or one follow-up).
