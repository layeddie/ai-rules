# OpenCode Guide

This document contains OpenCode-specific setup and operating details.
Core policy remains in `AGENTS.md`.

## Mode Files

- Plan: `.opencode/opencode.plan.json`
- Build: `.opencode/opencode.build.json`
- Review: `.opencode/opencode.review.json`
- MCP config: `.opencode/opencode_mcp.json`

## Mode Intent

- Plan: read-only discovery and architecture mapping.
- Build: implementation + tests + iterative validation.
- Review: read-only quality/performance/correctness audit.

## Recommended Tool Usage

- `rg`: exact and regex search.
- `mgrep`: conceptual/semantic pattern search.
- Serena MCP: semantic navigation/editing for larger refactors.

## Standard OpenCode Checks

```bash
mix format
mix credo --strict
mix test
# optional:
mix dialyzer
```

## Nix

If using Nix, enter the project shell first:

```bash
nix develop -c bash -lc 'mix test'
```

Use `AI_RULES_SILENT=1` to suppress extra shell banner output.
