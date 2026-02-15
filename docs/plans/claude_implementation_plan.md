## Context

- - Source https://github.com/georgeguimaraes/claude-code-elixir - attribtion required.
- - Need attribution section added to bottom of main README.md
- - Goal: Add Claude-only bridge assets while keeping ai-rules tool-agnostic and OpenCode defaults untouched.
- Scope: Confine new files under `tools/claude/` and mirror end-user templates in `templates/` for easy project copy. No Cursor changes this pass.
- Status update (2026-02-14): attribution section has been added to `README.md`.

## Branch

- Working branch: `codex/claude-bridge-plan` (created).

## Plan (do not implement in this file; for execution later)

1. **Asset layout**
   - Create `tools/claude/hooks/` with JSON or shell snippets for block/warn checks (missing @impl, hardcoded paths/sizes, static_paths, nested if, inefficient Enum, string concat).
   - Create `tools/claude/skills/` containing:
     - `skill-discovery` meta-skill (INVOKE BEFORE, file-pattern hints).
     - Mapped BEAM skills aligned with ai-rules personas (otp-patterns, ecto-query-analysis, liveview, ash policy/query guardrails).
   - Add `tools/claude/CLAUDE.md.template` customized to ai-rules structure and BEAMAI persona.
   - Add `tools/claude/claude_settings.example.json` showing how to merge hooks without overriding user config.
   - Add `tools/claude/scripts/install_claude_hooks.sh` for optional merge/apply; keep idempotent, no auto-run.

2. **Mirrored templates for users**
   - Mirror `CLAUDE.md.template` and hook bundle into `templates/claude/` to enable quick copy into projects without touching `tools/`.

3. **Docs updates (minimal)**
   - Update `tools/claude/README.md` to reference new assets and clarify opt-in nature.
   - Update repo `README.md` with a brief “Optional Claude setup” pointer to `tools/claude`.
   - Update `tools/README.md` to note Claude assets location and mirror in `templates/claude/`.
   - Add a short note in `docs/quickstart-agents.md` linking to Claude bridge (no workflow changes).

4. **Non-goals / constraints**
   - No changes to `.opencode/` configs, OpenCode flows, or Cursor rules.
   - Keep hooks confined to optional scripts/snippets; no enforcement by default.
   - Preserve subscription-free positioning; Claude bits are opt-in.

5. **Validation (post-implementation)**
   - Run `mix format` only if Elixir files touched (not expected).
   - Basic shellcheck on install script.
   - Verify new docs reference correct paths.

## Open Questions

- Do we also want a tiny `mix quality` task to mirror hook logic outside Claude? (currently out of scope per request).
- Any naming preference for the mirrored template folder (`templates/claude/` chosen for now)?

## Next Steps

- Implement according to steps above, committing in small chunks. (Completed on branch `codex/claude-bridge-plan`: assets/hooks/skills/templates/docs + optional mix quality snippet.)
