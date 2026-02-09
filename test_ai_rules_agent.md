# ai_rules_agent quick test guide

## Prereqs
- `nix develop .#universal` (or Elixir/OTP 1.17/27 + Req installed)

## Run the suite
```bash
cd tools/ai_rules_agent
mix deps.get
mix ci        # format + credo --strict + test
# or just
mix test
```

## HTTP lifecycle smoke
```bash
# from repo root
AI_AGENT=1 AI_AGENT_SECRET=dev MIX_ENV=test mix run scripts/ai/serve_agent.exs
# in another shell
curl -X POST http://localhost:4040/agents/start \
  -H "x-ai-agent-secret: dev" \
  -H "content-type: application/json" \
  -d '{"strategy":"react","provider":"stub","model":"test"}'
```

## Stdio smoke
```bash
AI_AGENT=1 MIX_ENV=test mix run scripts/ai/serve_agent_stdio.exs
echo '{"op":"agents/list","args":{}}' | nc localhost 4040
```

## Bundled tools
- `AiRulesAgent.Tools.WebFetch` (HTTP GET)
- `AiRulesAgent.Tools.WebSearch` (DuckDuckGo)
- `AiRulesAgent.Tools.FileSearch` (allowlisted grep)

## Memory adapters
- File, Log, “SQLite” (file-backed); select via `memory:`, `memory_id:`.

## Known gaps (next)
- Vector store adapter (pgvector/sqlite-vss) for RAG; current RAG.MemoryIndex is in-memory only.
