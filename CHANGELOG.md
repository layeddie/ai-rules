# Changelog

## Unreleased
- Provider-configurable HTTP/stdio lifecycle endpoints with openai/anthropic/openrouter/stub providers.
- Strategies: ReAct, CoT, Tree-of-Thought.
- Tool validation via JSON Schema with `schema` or `schema_spec`.
- Transports: OpenAI, Anthropic, OpenRouter helpers.
- Memory adapters: file, “sqlite” (file-backed).
- Tool schema helper `AiRulesAgent.ToolSchema`.
- CI alias `mix ci` (format + credo --strict + test).
