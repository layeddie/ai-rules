# Skill: ecto-query-analysis

**INVOKE BEFORE** writing/reviewing queries, migrations, or Repo calls.

## Use when
- Lists are slow; possible N+1.
- Adding associations or migrations.
- Reviewing Repo usage inside LiveView or GenServer.

## Checklist
- Preload associations explicitly; avoid query-time N+1.
- Add DB indexes for foreign keys and common filters.
- Prefer `select` with fields needed; avoid loading blobs.
- Use `Repo.transaction/1` for multi-step mutations.
- In LiveView, keep Repo calls out of `handle_event` unless throttled.
- Validate changesets in context/resource layer, not controllers.

## Quick patterns
- Batch preload: `Repo.preload(records, [:assoc])`.
- Windowing/pagination: `limit/2`, `offset/2`, or keyset paging libs.
- Concurrency: wrap in `Task.async_stream/5` only for read-heavy workloads; never inside Repo transactions.

## Warnings to emit
- Repo calls in render.
- Queries inside Enum.map leading to N+1.
- Missing unique/foreign key indexes after migrations.
