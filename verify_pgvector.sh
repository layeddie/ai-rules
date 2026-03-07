#!/usr/bin/env bash

set -euo pipefail

echo "=== pgvector Verification ==="
echo ""

PG_BIN=${PG_BIN:-/opt/homebrew/opt/postgresql@16/bin/psql}
DB_HOST=${ARCANA_DB_HOST:-localhost}
DB_PORT=${ARCANA_DB_PORT:-5432}
DB_USER=${ARCANA_DB_USER:-$(whoami)}
DB_NAME=${ARCANA_DB_NAME:-ai_rules_context}

if [[ ! -x "$PG_BIN" ]]; then
  echo "1. Checking psql binary..."
  echo "   x psql not found at $PG_BIN"
  echo "   Set PG_BIN to your psql path."
  exit 1
fi

echo "1. Checking database connectivity..."
if "$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1;" >/dev/null; then
  echo "   ok PostgreSQL is reachable on ${DB_HOST}:${DB_PORT}"
else
  echo "   x Could not connect to PostgreSQL on ${DB_HOST}:${DB_PORT}"
  exit 1
fi

echo ""
echo "2. Checking target database..."
DB_EXISTS=$("$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';")

if [[ "$DB_EXISTS" == "1" ]]; then
  echo "   ok Database '$DB_NAME' exists"
else
  echo "   x Database '$DB_NAME' does not exist"
  echo "   Create it first or set ARCANA_DB_NAME."
  exit 1
fi

echo ""
echo "3. Checking pgvector extension..."
if "$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null; then
  echo "   ok vector extension is available/enabled"
else
  echo "   x Could not enable vector extension in '$DB_NAME'"
  exit 1
fi

echo ""
echo "4. Checking vector operations..."
if "$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT '[1,2,3]'::vector;" >/dev/null; then
  echo "   ok Vector operations are working"
else
  echo "   x Vector operations failed"
  exit 1
fi

echo ""
echo "=== ALL CHECKS PASSED ==="
echo "pgvector is ready for Arcana."
