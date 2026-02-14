# ReqLLM (Optional)

Unified, Req-based LLM client with high-level helpers (`generate_text/3`, `stream_text/3`, `generate_object/4`) and a low-level Req plugin for custom pipelines. Version 1.5.0 (Feb 1, 2026) adds broad provider coverage with models.dev-synced metadata. citeturn0search2turn0search5

## When to use
- You want a single client that works across OpenAI, Anthropic, Google, Groq, xAI, OpenRouter, and more without bespoke HTTP code. citeturn0search5
- You need streaming plus structured outputs with normalized response structs and tool-call events. citeturn0search6
- You want per-call usage/cost metadata and a telemetry hook for budgets/observability. citeturn0search7

## Install (opt-in per project/template)
1. In `mix.exs` (templates already mark it optional), ensure:
   ```elixir
   {:req_llm, "~> 1.5", optional: true}
   ```
2. Add to `mix.exs` `extra_applications: [:logger]` (already present in templates).
3. Run `mix deps.get` only when you plan to call LLMs.

## Key management (precedence)
- Per-call options (`api_key`, `organization`), then app env/config, then `.env`/ENV (`REQ_LLM_PROVIDERS_JSON`, provider-specific keys), matching the library defaults. Keep keys out of git; use `.env` or Nix shell env vars.

## Provider choices (subscription-free friendly)
- Prefer free-tier or paid-by-usage providers when available: GitHub Models (preview), OpenRouter (promos), local OpenAI-compatible endpoints (LM Studio, Ollama with openai plugin). 
- For fully local, point ReqLLM at an OpenAI-compatible base URL and supply a dummy key.

## Streaming notes
- Streams arrive as `ReqLLM.StreamChunk` events (`:content`, `:tool_call`, `:meta`, etc.), normalized across providers for LiveView/Phoenix consumption. citeturn0search6

## Telemetry & observability
Attach to token/cost usage for every request:
```elixir
:telemetry.attach(
  "req-llm-usage",
  [:req_llm, :token_usage],
  fn _event, measurements, metadata, _ ->
    Logger.info("req_llm usage", measurements: measurements, metadata: metadata)
  end,
  nil
)
```
Measurements include `input_tokens`, `output_tokens`, `total_tokens`, `input_cost`, `output_cost`, `total_cost`, and `reasoning_tokens` when present. citeturn0search7

## Model metadata sync (optional)
- Update provider/model catalog and pricing: `mix req_llm.model_sync` (add `--verbose` for progress). citeturn0search4
- Only run when you need fresh pricing/capability data; keep out of default CI to avoid network cost.

## Fixture checks (optional)
- Use `scripts/req_llm_fixture_check.sh` to run fixture tests: set `REQ_LLM_FIXTURES_MODE=record` with your keys to regenerate fixtures; default mode replays recorded fixtures.

## Example module
- See `templates/llm/req_llm_example.ex` for Phoenix controller + LiveView streaming + tool-call handling, ready to copy into new projects.

## Validation checklist (when you enable it)
- `mix format`
- `mix credo --strict`
- `mix test`
- Optional: `REQ_LLM_FIXTURES_MODE=record mix test`
- Optional: `mix dialyzer` (if PLTs available)
