#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CONTEXT_DIR="$ROOT_DIR/tools/arcana_context"

PG_BIN=${PG_BIN:-/opt/homebrew/opt/postgresql@16/bin/psql}
DB_HOST=${ARCANA_DB_HOST:-localhost}
DB_PORT=${ARCANA_DB_PORT:-5432}
DB_USER=${ARCANA_DB_USER:-$(whoami)}
DB_NAME=${ARCANA_DB_NAME:-ai_rules_context}

if ! command -v elixir >/dev/null 2>&1; then
  echo "Elixir is required."
  exit 1
fi

ELIXIR_VERSION=$(elixir --version | awk '/Elixir/{print $2}')
ELIXIR_MAJOR=$(echo "$ELIXIR_VERSION" | cut -d. -f1)
ELIXIR_MINOR=$(echo "$ELIXIR_VERSION" | cut -d. -f2)

if [[ "$ELIXIR_MAJOR" -lt 1 || "$ELIXIR_MINOR" -lt 18 ]]; then
  echo "Arcana requires Elixir 1.18+."
  echo "Current version: $ELIXIR_VERSION"
  echo "Run setup from an Elixir 1.18 environment, then rerun this script."
  exit 1
fi

if [[ ! -x "$PG_BIN" ]]; then
  echo "psql binary not found at $PG_BIN"
  echo "Set PG_BIN to your psql location."
  exit 1
fi

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "Arcana sidecar missing at $CONTEXT_DIR"
  exit 1
fi

echo "Ensuring database '$DB_NAME' exists..."
DB_EXISTS=$("$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME';")

if [[ "$DB_EXISTS" != "1" ]]; then
  "$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE \"$DB_NAME\";"
fi

echo "Ensuring pgvector extension is enabled..."
"$PG_BIN" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

cd "$CONTEXT_DIR"

echo "Installing Elixir dependencies..."
mix deps.get

if compgen -G "priv/arcana_context_repo/migrations/*arcana*.exs" > /dev/null; then
  echo "Arcana migrations already present, skipping mix arcana.install"
else
  echo "Running mix arcana.install..."
  mix arcana.install
fi

echo "Running migrations..."
mix ecto.migrate

echo "Arcana sidecar setup complete."
