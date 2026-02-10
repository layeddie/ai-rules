#!/usr/bin/env bash
set -euo pipefail

# Run ReqLLM fixture tests. Intended to be opt-in and safe for CI.
# Usage:
#   ./scripts/req_llm_fixture_check.sh [project_dir]
# Env:
#   REQ_LLM_FIXTURES_MODE=replay|record (default: replay)
#   MIX_ENV=test (default)

project_root=${1:-.}
cd "$project_root"

if [ ! -f mix.exs ]; then
  echo "mix.exs not found; run from a Mix project root or pass the path" >&2
  exit 1
fi

mode=${REQ_LLM_FIXTURES_MODE:-replay}
export REQ_LLM_FIXTURES_MODE="$mode"
export MIX_ENV=${MIX_ENV:-test}

# Only run tests tagged for req_llm fixtures to avoid hitting live providers by default.
# Projects should tag relevant tests with `@tag :req_llm_fixture`.
echo "[req_llm] mode=$mode MIX_ENV=$MIX_ENV"
mix test --only req_llm_fixture
