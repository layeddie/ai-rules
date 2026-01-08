#!/bin/bash
set -e

echo "[1/5] Installing usage_rules..."
mix deps.get usage_rules 2>/dev/null || {
  echo "usage_rules not found in deps, checking if in mix.exs..."
  if ! grep -q "usage_rules" mix.exs; then
    echo "Error: usage_rules not in mix.exs"
    exit 1
  fi
}

echo "[2/5] Syncing rules from dependencies..."
mix usage_rules.sync AGENTS.md --all \
  --link-to-folder deps \
  --inline usage_rules:all

if [ $? -eq 0 ]; then
  echo "✅ usage_rules synced successfully"
  echo ""
  echo "Next steps:"
  echo "  1. Review synced rules in AGENTS.md"
  echo "  2. Run 'mix usage_rules.search_docs <query>' to search hexdocs"
  echo "  3. Run 'mix usage_rules.sync --list' to check status"
else
  echo "❌ usage_rules sync failed"
  exit 1
fi
