#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
CONTEXT_DIR="$ROOT_DIR/tools/arcana_context"

if [[ ! -d "$CONTEXT_DIR" ]]; then
  echo "Arcana sidecar missing at $CONTEXT_DIR"
  exit 1
fi

export AI_RULES_ROOT="$ROOT_DIR"

cd "$CONTEXT_DIR"
mix arcana_context.ingest --root "$ROOT_DIR" --core-only "$@"
