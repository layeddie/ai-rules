# Arcana Sidecar (Tool-Agnostic)

Use this when you want semantic retrieval over `ai-rules` docs for any AI agent (Codex, OpenCode, Claude, Cursor, custom scripts).

Arcana sidecar requires Elixir 1.18+.
If you use Nix in this repo, enter a 1.18 shell first:

```bash
nix develop /Users/elay14/projects/2026/ai-rules/tools/nixos/flakes/universal.nix#elixir_1_18_erlang_27
```

## 1) Setup once

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_setup.sh
```

## 2) Ingest ai-rules docs

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_ingest_ai_rules_docs.sh
```

This defaults to a faster core-doc ingest. Use `--full` for the full corpus.
For a very fast first pass, ingest explicit paths:

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_ingest_ai_rules_docs.sh --path docs/quickstart-agents.md --path README.md
```

Defaults to local embeddings (`ARCANA_EMBEDDER=local`). To use OpenAI instead:

```bash
export ARCANA_EMBEDDER=openai
export OPENAI_API_KEY=your_key
```

Optional:

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/download_guides.sh
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_ingest_ai_rules_docs.sh
```

This adds Phoenix guides from `.rules-phoenix/guides` if present.

## 3) Search from any agent or terminal

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_search_ai_rules_docs.sh "How should Ash actions be organized?"
```

## 4) Shared query pattern for agent prompts

Use this shell call in your agent workflow before code changes:

```bash
bash /Users/elay14/projects/2026/ai-rules/scripts/arcana_search_ai_rules_docs.sh --limit 8 "<your task query>"
```

## Notes

- Arcana remains optional and separate from core `ai-rules` workflow.
- `mgrep + serena` stays the default path for day-to-day coding.
- Arcana is used when you need retrieval across broad local documentation context.
