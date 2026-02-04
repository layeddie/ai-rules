# Implementation Plan: Token-Friendly AI Usage

## Goals
- Reduce prompt/token weight while keeping ai-rules guidance clear.
- Make agent onboarding faster (quickstart) and keep detailed matrices in appendices.
- Allow quiet shellHooks when contexts are streamed.

## Work Items
1) **AGENTS.md trim**
   - Scope: Keep top-level modes/tools table + links only; move role details to existing `roles/*.md` (already present).
   - Deliverable: AGENTS.md ≤ ~250 lines; add “Read roles/* for details” link.

2) **Quickstart one-pager**
   - File: `docs/quickstart-agents.md`
   - Contents: commands per mode (plan/build/review), which config to use, 6–8 bullet directory map (reuse README structure), minimal checklist before running (nix develop, mix deps.get).
   - Cross-link: From AGENTS.md and README.md.

3) **Project requirements slimming**
   - File: `configs/project_requirements.md`
   - Action: Move long LLM/model matrices + Tidewave Q&A to an appendix section at bottom (or separate `configs/appendix_llm_models.md`), keep main body to: stack versions, tool choices, architecture, testing, concise structure.
   - Target: main body ≤ ~250 lines.

4) **ShellHook verbosity toggle (optional but easy)**
   - Files: `configs/nix_flake_*.nix`
   - Add env guard `if [ "${AI_RULES_SILENT:-0}" = "1" ]; then return; fi` around banner block; keep commands available.
   - Document env toggle in quickstart.

5) **Cleanup after changes**
   - Run: `mix format` (for any .ex changes), `git status`, `git push` via feature branch per git_rules.

## Branching & PR
- Branch name: `codex/token-slimming`
- Conventional commit suggestions:
  - `docs: add ai quickstart and slim agents`
  - `chore: trim project requirements body`
  - `chore: add shellhook quiet toggle`

## Definition of Done
- AGENTS.md shorter, defers detail to roles/docs.
- README links to quickstart; quickstart exists.
- project_requirements main body lean; detailed matrices relocated.
- Nix shellHook quiet mode works when `AI_RULES_SILENT=1`.
- All scripts still pass basic validation (`scripts/validate_requirements.sh` in a generated project).
