# Nix Flake Runbook

This repository uses a per-project `flake.nix` standard.

## Canonical template

- Universal template source: `/Users/elay14/projects/2026/ai-rules/tools/nixos/flakes/universal.nix`
- `ai-rules` root `flake.nix` imports this template directly.

## Standard commands

### ai-rules

```bash
cd /Users/elay14/projects/2026/ai-rules
nix develop -c bash -lc 'mix --version && elixir --version'
```

### ai_rules_agent

```bash
cd /Users/elay14/projects/2026/ai_rules_agent
nix develop -c bash -lc 'mix deps.get && mix test'
```

### Explicit flake path (from any directory)

```bash
nix develop /Users/elay14/projects/2026/ai-rules -c bash -lc 'mix --version'
nix develop /Users/elay14/projects/2026/ai_rules_agent -c bash -lc 'mix --version'
```

## Task mapping

- Install deps: `nix develop -c bash -lc 'mix deps.get'`
- Compile: `nix develop -c bash -lc 'mix compile'`
- Test: `nix develop -c bash -lc 'mix test'`
- Lint: `nix develop -c bash -lc 'mix credo --strict'`
- Type check: `nix develop -c bash -lc 'mix dialyzer'`

## Notes

- Keep generated `.nix-hex/` and `.nix-mix/` out of git.
- Use `AI_RULES_SILENT=1` when you want less shell banner noise.
