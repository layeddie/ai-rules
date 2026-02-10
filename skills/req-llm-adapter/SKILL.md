# Skill: ReqLLM Adapter (Serena/Codex)

Goal: Give agents a compact, provider-agnostic recipe for using `req_llm` in BEAM projects (OpenCode/Serena/Codex). Keep opt-in and align with `docs/req_llm.md`.

## When to use
- Project wants a unified LLM client without bespoke HTTP calls.
- Need standard prompts for `generate_text/3`, `stream_text/3`, or `generate_object/4`.
- Need to surface usage/cost telemetry and keep keys out of git.

## Quick setup (per project)
1) Ensure dep is available (templates mark optional): `{:req_llm, "~> 1.5", optional: true}`.
2) Keys via env or `.env` (preferred): `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, or `REQ_LLM_PROVIDERS_JSON`.
3) For local endpoints (LM Studio/Ollama with OpenAI plugin) set `REQ_LLM_OPENAI_BASE_URL` and a dummy key.
4) Add a thin wrapper module (or copy from `templates/llm/req_llm_example.ex`) and wire telemetry hook below.

## Prompt snippets (drop into agent messages)
- Text:
  ```
  Use ReqLLM.generate_text/3 with opts:
  - :provider (e.g., :openai, :anthropic, :openrouter)
  - :model (string)
  - :messages (list of %{role: :user|:assistant|:system, content: string})
  - :max_output_tokens (optional)
  Return {:ok, %ReqLLM.Response{content, usage}} or {:error, reason}.
  ```
- Streaming:
  ```
  Use ReqLLM.stream_text/3. Consume stream of %ReqLLM.StreamChunk{type: :content|:tool_call|:meta, data: ...}.
  Accumulate content chunks; handle :tool_call separately.
  ```
- Object generation:
  ```
  Use ReqLLM.generate_object/4 with a JSON schema map under :response_schema.
  Expect {:ok, %{object: map(), usage: usage}} or {:error, reason}.
  ```

## Telemetry hook
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
Measurements include tokens and cost fields; safe to forward to OTEL/Logger.

## Guardrails
- Keep HTTP/1 Finch pools unless you’ve validated HTTP/2 with your stack.
- Never commit keys; prefer env/direnv/Nix devshell vars.
- Mark the dep optional to avoid pulling LLM libs when unused.
- For CI, skip `mix req_llm.model_sync` unless explicitly needed.

## Validation checklist (when enabled)
- `mix format`
- `mix credo --strict`
- `mix test`
- Optional: `REQ_LLM_FIXTURES_MODE=record mix test` (with keys)
- Optional: `mix dialyzer` (if PLTs available)

## Pointers
- Full doc: `docs/req_llm.md`
- Example module: `templates/llm/req_llm_example.ex`
