## Context
- Goal: Add ReqLLM support while keeping ai-rules provider-agnostic and subscription-free friendly (works with free-tier/local providers when available).
- Current state: ai-rules ships generic LLM guidance only; no unified client. ReqLLM 1.5.0 (Feb 01, 2026) adds stable API, 11+ providers, 600+ models with cost/metadata sync; aligns with Req + Finch stack already used in many Phoenix apps.
- Constraints: Keep optional/opt-in; avoid forcing paid keys; maintain compatibility with OpenCode/BEAMAI personas and existing devshells.

## Branch
- Working branch: `codex/req-llm-plan` (created).

## Plan (do not implement here; for execution later)
1) **Library wiring (optional profile)**
   - Add `req_llm` dep to `mix.exs` (only in template/optional profile, not core) with app env for provider keys precedence (`REQ_LLM_PROVIDERS_JSON`, `.env`, config, per-call override).
   - Extend devshell (`flake.nix` / `shell.nix` if present) with `REQ_LLM_*` env stubs and `req_llm.model_sync` tool availability; keep default disabled.
   - Provide `lib/ai_rules/llm/req_llm.ex` thin wrapper exposing `generate_text/3`, `stream_text/3`, `generate_object/4` plus telemetry hook forwarding to OpenTelemetry/Logger.

2) **Docs & quickstart**
   - Add `docs/req_llm.md` covering install, key management precedence, provider selection matrix (GitHub Models/OpenRouter/self-hosted), and streaming notes (HTTP/1 vs HTTP/2 pools).
   - Update `docs/quickstart-agents.md` and `README.md` with an “Optional: ReqLLM” section pointing to the new doc and template toggle.
   - Add cost/usage observability snippet showing `[:req_llm, :token_usage]` telemetry to `logger_json` / OTEL exporter.

3) **Templates & examples**
   - Create template module under `templates/llm/req_llm_example.ex` demonstrating Phoenix controller + LiveView streaming + tool calling with pattern-matched error handling.
   - Provide `.env.example` additions for common providers (OpenAI, Anthropic, OpenRouter, GitHub Models) and notes on free/local choices.
   - Add mix task alias or script `scripts/req_llm_fixture_check.sh` to run fixture tests selectively (`REQ_LLM_FIXTURES_MODE=record` opt-in).

4) **Quality gates**
   - Ensure `mix credo --strict` and `mix dialyzer` configs are updated for new wrapper module (types for usage metadata).
   - Add unit tests mirroring wrapper + a property-based test for cost aggregation when multiple tool calls return partial usage.
   - Document validation steps in plan checklist; run `mix test`, `mix format`, credo; live provider tests are opt-in.

5) **Non-goals / constraints**
   - No default enforcement of HTTP/2 pools; keep Finch defaults (HTTP/1) to avoid known large-body bug.
   - Do not break existing OpenCode/Claude/Cursor workflows; keep new assets additive and opt-in.
   - Avoid coupling to any single provider pricing; emphasize metadata-driven selection and free-tier notes.

## Validation (post-implementation)
- `mix format` (if Elixir files touched)
- `mix credo --strict`
- `mix test`
- Optional: `REQ_LLM_FIXTURES_MODE=record mix test` against user-provided keys
- Optional: `mix dialyzer` if PLT available in repo

## Open Questions
- Do we want a minimal `req_llm` adapter skill for Serena/Codex to standardize prompts? (could live under `skills/`.)
- Should the template default to OpenRouter + GitHub Models as “subscription-free” examples, or leave blank to avoid endorsement?
- Do we expose model metadata sync (`mix req_llm.model_sync`) in CI, or keep manual to reduce network during builds?
