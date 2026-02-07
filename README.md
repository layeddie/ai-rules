# ai_rules_agent (design sketch)

Goal: Hex package that ships the AI agent surface (tasks, HTTP/stdio servers, allowlist, docs) so projects can `{:ai_rules_agent, "~> 0.1"}` and run.

Included components:
- Mix tasks: `ai.dump`, `ai.test`, `ai.guidelines`.
- Dev-only servers: HTTP (Bandit) and stdio sharing the same handlers.
- Plug module: `AiRulesAgent.API` (read/patch/test/doc, allowlist + patch guard).
- Allowlist policy file template.
- Simple doc lookup (grep-based) until Hexdocs cache lands.
- Installer task: `mix ai_rules_agent.install` to copy `ai/` scaffold and scripts into host project.

Status: skeleton; not published.
