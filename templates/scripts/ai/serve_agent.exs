#!/usr/bin/env elixir
# Starts the AI Agent HTTP API in dev mode (Bandit). Requires AI_AGENT=1.
# Usage: MIX_ENV=dev AI_AGENT=1 mix run scripts/ai/serve_agent.exs

Mix.install([
  {:bandit, "~> 1.5"},
  {:jason, "~> 1.4"}
])

port = String.to_integer(System.get_env("AI_AGENT_PORT") || "4040")

IO.puts("Starting TestProject.AiAgentAPI on http://localhost:#{port} (AI_AGENT=1 required)")

{:ok, _} = Bandit.start_link(plug: TestProject.AiAgentAPI, scheme: :http, port: port)

Process.sleep(:infinity)
