# Arcana Context (Sidecar)

This project keeps Arcana-based document retrieval separate from core `ai-rules` workflows.

## Why a sidecar

- Optional: users who do not need RAG do not pay setup/runtime cost.
- Tool-agnostic: any AI agent can call shared scripts instead of OpenCode-only config.
- Local-first: indexes `ai-rules` docs into local Postgres + pgvector.

## Prerequisites

1. Elixir 1.18+.
2. PostgreSQL running locally.
3. `pgvector` extension available.
4. Database `ai_rules_context` created (or set `ARCANA_DB_NAME`).

## Setup

From repo root:

```bash
bash scripts/arcana_setup.sh
```

This script:
- ensures the target database exists,
- enables `vector` extension,
- installs dependencies,
- runs `mix arcana.install` once,
- runs migrations.

## Ingest docs

```bash
bash scripts/arcana_ingest_ai_rules_docs.sh
```

By default this runs a faster core-doc ingest.

Optional flags:

```bash
bash scripts/arcana_ingest_ai_rules_docs.sh --collection ai_rules_docs
bash scripts/arcana_ingest_ai_rules_docs.sh --skip-phoenix-guides
bash scripts/arcana_ingest_ai_rules_docs.sh --full
bash scripts/arcana_ingest_ai_rules_docs.sh --path docs/quickstart-agents.md
bash scripts/arcana_ingest_ai_rules_docs.sh --path README.md --path patterns/PATTERN_INDEX.md
```

## Search docs

```bash
bash scripts/arcana_search_ai_rules_docs.sh "How should OTP supervision be structured?"
```

Optional:

```bash
bash scripts/arcana_search_ai_rules_docs.sh --limit 12 "How do I choose plan vs build mode?"
```

## Useful corpus notes

- The ingest task indexes core `ai-rules` docs (`README`, `AGENTS`, `docs/`, `patterns/`, `skills/**/SKILL.md`).
- If `.rules-phoenix/guides` exists (via `scripts/download_guides.sh`), those guides are also indexed by default.

## Environment variables

- `AI_RULES_ROOT`: override detected repo root.
- `ARCANA_DB_HOST` (default `localhost`)
- `ARCANA_DB_PORT` (default `5432`)
- `ARCANA_DB_USER` (default current shell user)
- `ARCANA_DB_PASSWORD` (default empty)
- `ARCANA_DB_NAME` (default `ai_rules_context`)
- `ARCANA_EMBEDDER` (`local` or `openai`, default `local`)
- `OPENAI_API_KEY` required only if `ARCANA_EMBEDDER=openai`

## Direct Mix tasks

Inside `tools/arcana_context`:

```bash
mix arcana_context.ingest
mix arcana_context.search "query text"
```
