# ai_rules_agent (design sketch)

Goal: Hex package that ships the AI agent surface (tasks, HTTP/stdio servers, allowlist, docs) so projects can `{:ai_rules_agent, "~> 0.1"}` and run.

Included components:
- Mix tasks: `ai.dump`, `ai.test`, `ai.guidelines`.
- Dev-only servers: HTTP (Bandit) and stdio sharing the same handlers.
- Plug module: `AiRulesAgent.API` (read/patch/test/doc, allowlist + patch guard).
- Allowlist policy file template.
- Simple doc lookup (grep-based) until Hexdocs cache lands.
- Installer task: `mix ai_rules_agent.install` to copy `ai/` scaffold and scripts into host project.
- NEW (draft): OTP agent runtime (`AgentSupervisor`, `AgentServer`) plus strategy behaviour and ReAct strategy.

Status: skeleton; not published.

## Agent runtime (draft)

Why: we want an OTP-native agent loop that mirrors Laravel AI SDK ergonomics (strategies, tools, transports), but keeps BEAM strengths: supervision, lightweight processes, and tool isolation.

Pieces:
- `AiRulesAgent.AgentSupervisor` — DynamicSupervisor to host many short-lived agents (per conversation).
- `AiRulesAgent.AgentServer` — GenServer that runs a strategy with a bounded step loop. It executes tools inside the process to keep state in sync.
- `AiRulesAgent.AgentManager` — start/stop/list convenience wrapper used by lifecycle endpoints.
- `AiRulesAgent.Strategy` — behaviour for strategies (`init/2`, `next/7`, optional `handle_tool_result/9`).
- Strategies:
  - `AiRulesAgent.Strategies.ReAct` — minimal ReAct; expects an `llm_fun` that returns either `content` or `tool_call`.
  - `AiRulesAgent.Strategies.CoT` — chain-of-thought; never calls tools, prepends a system prompt and returns content directly.
  - `AiRulesAgent.Strategies.TreeOfThought` — two-phase: generate candidate thoughts, then rank/select best.
- `AiRulesAgent.Transports.OpenAI.llm_fun/1` — helper to build an `llm_fun` that hits OpenAI-compatible chat endpoints via Req.
- `AiRulesAgent.Transports.Anthropic.llm_fun/1` — Anthropic Messages API helper.
- `AiRulesAgent.Transports.OpenRouter.llm_fun/1` — OpenRouter helper (OpenAI-compatible).
- Tool validation: tools can include `schema` (JSON Schema map) or `schema_spec` (see below). Args are validated via ExJsonSchema before execution; invalid args return `{:error, {:invalid_tool_args, reason}}`.
- Memory:
  - `AiRulesAgent.Memory.File` — ETS + file-backed history store under `priv/ai_memory/` keyed by `memory_id`.
  - `AiRulesAgent.Memory.SQLite` — ETS cache + `priv/ai_memory.sqlite3` for persistence.
  - Tool schema helper: `AiRulesAgent.ToolSchema.from_spec/1` turns simple specs (e.g., `%{n: :integer, tags: {:list, :string}}`) into JSON Schema; set `schema_spec` on a tool to auto-compile.

Minimal usage sketch:
```elixir
# Define LLM transport (OpenAI, Anthropic, etc.)
llm_fun = AiRulesAgent.Transports.OpenAI.llm_fun(model: "gpt-4.1", api_key: System.fetch_env!("OPENAI_API_KEY"))

# Define tools (name => fn args -> result end)
tools = %{
  "add" => fn %{"a" => a, "b" => b} -> a + b end
}

# Start supervisor and an agent
{:ok, sup} = AiRulesAgent.AgentSupervisor.start_link([])
{:ok, pid} =
  AiRulesAgent.AgentSupervisor.start_agent(sup,
    strategy: AiRulesAgent.Strategies.ReAct,
    llm_fun: llm_fun,
    tools: tools,
    max_steps: 5
  )

# Ask
{:ok, reply} = AiRulesAgent.AgentServer.ask(pid, "What is 2+3?")
IO.inspect(reply, label: \"assistant\")
```

Behaviour contract:
- `llm_fun` receives a map with `:messages` (history) and `:tools` (list of tool names). When invoked after a tool run, it also receives `:tool_result`. Return `{:ok, %{content: binary}}` or `{:ok, %{tool_call: %{name: binary, args: map()}, content: binary | nil}}`.
- Strategies decide when to stop; the server enforces `max_steps` to avoid loops.
- Tools are synchronous (arity 1 functions). Errors are trapped and returned as `{:error, {:tool_error, e}}`.
- Memory (optional): pass `memory: AiRulesAgent.Memory.File, memory_id: "session-123"` to persist history between process restarts.

Laravel AI SDK influence: strategies and transports stay decoupled; the Elixir runtime adds OTP supervision, explicit allowlists, and built-in step guards. Transports stay pluggable through `llm_fun`, mirroring Laravel's driver model while leaning on BEAM processes for safety.

## Install & test locally (via flake.nix)

```bash
# enter dev shell (includes Elixir/OTP)
nix develop .#universal

# install deps
cd tools/ai_rules_agent
mix deps.get

# run the suite (agent runtime + API helpers)
mix test

# optional CI bundle (format + credo --strict + test)
mix ci
```

## Session logging helper
- Run `./scripts/log_session.sh` from repo root to append a stub entry under `ai/sessions/<date>.md` (directory is gitignored). Fill in Notes/Actions/Follow-ups as you work.

## Stdio server ops
- Start stdio server: `AI_AGENT=1 MIX_ENV=dev mix run scripts/ai/serve_agent_stdio.exs`
- Supported ops (JSON lines): `ctx/routes`, `ctx/ash`, `fs/read`, `fs/patch`, `test`, `doc/lookup`, `agents/start`, `agents/stop`, `agents/list`. Include `secret` if `AI_AGENT_SECRET` is set.

## HTTP lifecycle request example
POST `/agents/start` with body:
```json
{
  "strategy": "react",
  "provider": "openai",
  "model": "gpt-4o",
  "api_key": "...",
  "headers": {"x-foo": "bar"},
  "memory": "file",
  "memory_id": "session-123"
}
```
Responses include `{"status":"ok","id": "...", "pid": "..."}` or `{"error": {code, message}}` with HTTP 400 on errors.
