# Project Requirements Appendix

This appendix exists to help users choose providers and models without turning `project_requirements.md` into a stale benchmark document.

## Selection Heuristics

### Planning
- Prefer a strong reasoning model.
- Optimize for architectural clarity, not raw token speed.
- Local models are fine if they can reliably hold repo-wide context.

### Build
- Prefer a model that is strong at iterative edits, refactors, and tool use.
- Optimize for latency and consistency across many short coding turns.
- Keep a stronger fallback available for complex rewrites or debugging.

### Review
- Prefer a model that is conservative, detail-oriented, and good at finding regressions.
- Optimize for correctness over speed.
- Use a different model from build if you want a second-pass perspective.

## Provider Questions

Before locking in a provider, answer:
- Is project code allowed to leave the machine?
- What is the per-developer monthly budget?
- Do you need offline or local-only work?
- Is latency or quality more important during build loops?
- Do you need MCP, streaming, or long-context support?

## Local Provider Notes

- `Ollama`: simple local setup, good default for local-first workflows.
- `LM Studio`: useful for desktop-managed local models and API compatibility.
- `MLX`: strong option on Apple Silicon when you want local acceleration.

## API Provider Notes

- Choose the provider that currently gives the best mix of reliability, cost, and quality for your team.
- Treat specific model names as time-sensitive. Re-evaluate them periodically instead of freezing them in core docs.

## Environment Variables

Only document variables that the project actually uses. Common examples:
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `OLLAMA_HOST`
- `LMSTUDIO_HOST`

## Guidance

- Keep this appendix out of default agent context unless model selection is part of the task.
- Update it when your real provider strategy changes, not when experimenting casually.
