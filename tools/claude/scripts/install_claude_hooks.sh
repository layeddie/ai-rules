#!/usr/bin/env bash
set -euo pipefail

# Optional helper to merge ai-rules Claude hooks into your Claude settings.json.
# Usage:
#   ./tools/claude/scripts/install_claude_hooks.sh ~/.claude/settings.json
#
# Requirements: jq

settings_path=${1:-}
if [[ -z "${settings_path}" ]]; then
  echo "usage: $0 /path/to/claude/settings.json" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for this script" >&2
  exit 1
fi

hooks_file="$(cd "$(dirname "$0")/.." && pwd)/hooks/hooks-settings.json"

tmp="${settings_path}.tmp.ai-rules"

if [[ ! -f "$settings_path" ]]; then
  echo "{\"hooks\": []}" >"$settings_path"
fi

jq --slurpfile ai_hooks "$hooks_file" '
  .hooks = (.hooks // []) + ($ai_hooks[0].hooks // [])
' "$settings_path" >"$tmp"

mv "$tmp" "$settings_path"
echo "Merged ai-rules hooks into $settings_path"
