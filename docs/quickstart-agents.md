# Quickstart for Agents (ai-rules)

## 0) Persona
- Default: **BEAMAI** (roles/beamai.md). Concise, expert on Elixir/OTP/Ash/Nix/Nerves.

## 1) Pick mode
- Plan: `opencode --config .opencode/opencode.plan.json`
- Build: `opencode --config .opencode/opencode.build.json`
- Review: `opencode --config .opencode/opencode.review.json`

## 2) Minimal checklist
- `nix develop` (select flake: phoenix_ash / universal / nerves).
- `mix deps.get`
- `mix format`
- `mix credo --strict`
- `mix test` (add `--cover` if needed)
- Optional: `mix dialyzer` if PLTs available.

## 3) Directory map (search-friendly)
```
ai-rules/ (this repo symlink)
.opencode/   # mode configs
config/      # env config only
lib/test_app/           # application + supervision
lib/test_app_ash/       # Ash domains/resources/actions/policies/notifiers/apis
lib/test_app_web/       # Phoenix LiveView/controllers (thin)
priv/repo/              # migrations/seeds
test/                   # mirrors lib/; support/, ash/, web/
flake.nix               # devshell
project_requirements.md # project brief
```

## 4) Tools
- ripgrep for exact/regex; mgrep for conceptual (see `docs/mixed-search-strategy.md`).
- Serena MCP for semantic search/edit in build/review.
- Silence banner noise: set `AI_RULES_SILENT=1` before `nix develop`.

## 5) Coding stance
- TDD; thin controllers; business logic in Ash actions/resources.
- OTP: supervised processes, avoid blocking callbacks, prefer pattern matching.
- DB: preload to avoid N+1; index critical queries.

## 6) Git workflow
- Branch from main (e.g., `codex/<short>`), conventional commits, PR before merge. See `git_rules.md`.
