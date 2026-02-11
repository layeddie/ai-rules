## Context
- Date: 2026-02-11
- Repo: `/Users/elay14/projects/2026/ai-rules`
- Goal: Align with `georgeguimaraes/claude-code-elixir` where valuable, without duplicating Claude assets added yesterday.
- Constraint: Keep OpenCode-first posture and Claude bridge optional.

## Branch
- Working branch: `codex/memento-arcana-implementation-plans`

## Non-Duplication Audit (baseline)
- Already in `ai-rules` (added 2026-02-10):
  - Skills: `skill-discovery`, `ash-guardrails`, `ecto-query-analysis`, `liveview-lifecycle`, `otp-patterns`
  - Hook bundle: `tools/claude/hooks/hooks-settings.json`
  - Installer and mirrored templates under `templates/claude/`
- Upstream `claude-code-elixir` provides:
  - Hooks/plugins: `mix-format`, `mix-compile`, `mix-credo`, `elixir-lsp`
  - Skills: `elixir-thinking`, `phoenix-thinking`, `ecto-thinking`, `otp-thinking`, `oban-thinking`, `using-elixir-skills`

## Plan
1. Build a capability mapping table (no copy-first)
- Map upstream skills to current assets:
  - `otp-thinking` -> `otp-patterns` (already covered)
  - `ecto-thinking` -> `ecto-query-analysis` (+ existing general skills)
  - `phoenix-thinking` -> `liveview-lifecycle` (+ repo-level liveview patterns)
  - `using-elixir-skills` -> `skill-discovery`
- Identify true gaps only (likely Oban-specific guidance).

2. Adopt hook logic, not duplicate packaging
- Review upstream hook script behavior and fold practical improvements into existing hook templates:
  - robust `mix.exs` discovery
  - compile lock avoidance when BEAM process is active
  - graceful skip when Credo absent
- Keep ai-rules hook format and installer flow; do not mirror upstream plugin folder structure.

3. Decide on LSP guidance (docs only)
- Add optional note in Claude docs for `elixir-lsp` plugin usage.
- Do not vendor upstream plugin assets into this repo.

4. Add explicit anti-duplication policy
- New policy in Claude docs:
  - prefer extending existing ai-rules skills
  - import upstream skill content only when there is no equivalent
  - if imported, record provenance and overlap decision in plan/docs

5. Optional gap-fill work (if approved tomorrow)
- Add one new focused skill only if gap is real (candidate: Oban operations patterns).
- Keep naming consistent with existing skill taxonomy.

## Shared Functionality with Other Plans
- Claude alignment should reference the same Memento/Arcana architecture terms from:
  - `docs/plans/ai_rules_memento_arcana_implementation_plan.md`
  - `docs/plans/ai_rules_agent_memento_arcana_implementation_plan.md`
- This keeps prompt/tooling guidance consistent across docs and runtime.

## Deliverables
- A capability mapping doc section preventing skill duplication.
- Hook hardening recommendations integrated into current Claude bridge flow.
- Clear decision record on whether Oban-specific skill is needed.

## Risks
- Silent skill duplication if mapping is not maintained.
- Overfitting docs to Claude and drifting from tool-agnostic goals.

## Next-Step Implementation Order (tomorrow)
1. Write mapping table and anti-dup policy
2. Apply hook hardening updates
3. Add optional elixir-lsp doc note
4. Decide on Oban skill gap with explicit yes/no decision
