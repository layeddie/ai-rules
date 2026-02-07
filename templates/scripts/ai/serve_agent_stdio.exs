#!/usr/bin/env elixir
# Minimal stdio loop exposing the same operations as the HTTP API for tools that prefer stdio (Cursor/Claude/OpenCode MCP-like).
# Usage: AI_AGENT=1 MIX_ENV=dev mix run scripts/ai/serve_agent_stdio.exs

Mix.install([
  {:jason, "~> 1.4"}
])

require Logger

if System.get_env("AI_AGENT") != "1" do
  IO.puts(:stderr, "AI_AGENT=1 required")
  System.halt(1)
end

handlers = %{
  "ctx/routes" => fn _ -> TestProject.AiAgentAPI.send_routes_payload() end,
  "ctx/ash" => fn _ -> TestProject.AiAgentAPI.send_ash_payload() end,
  "fs/read" => fn %{"path" => p, "start" => s, "end" => e} -> TestProject.AiAgentAPI.read_span_payload(p, s, e) end,
  "fs/patch" => fn %{"path" => p, "patch" => patch} -> TestProject.AiAgentAPI.patch_payload(p, patch) end,
  "test" => fn %{"file" => f} -> TestProject.AiAgentAPI.test_payload(f) end,
  "doc/lookup" => fn %{"term" => t} -> TestProject.AiAgentAPI.doc_lookup_payload(t) end
}

IO.puts("AI stdio server ready. Send JSON lines with keys: op, args")

Stream.repeatedly(fn -> IO.gets("") end)
|> Stream.take_while(&(&1))
|> Enum.each(fn line ->
  with {:ok, %{"op" => op, "args" => args}} <- Jason.decode(line),
       :ok <- ensure_secret(args),
       handler when is_function(handler, 1) <- Map.get(handlers, op) do
    resp = handler.(args || %{})
    IO.puts(Jason.encode!(%{ok: true, op: op, data: resp}))
  else
    {:error, reason} -> IO.puts(Jason.encode!(%{ok: false, error: reason}))
    nil -> IO.puts(Jason.encode!(%{ok: false, error: "unknown op"}))
  end
end)

defp ensure_secret(args) do
  case System.get_env("AI_AGENT_SECRET") do
    nil -> :ok
    secret when is_binary(secret) ->
      case args do
        %{"secret" => ^secret} -> :ok
        _ -> {:error, "unauthorized"}
      end
  end
end
