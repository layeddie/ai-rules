defmodule AiRulesAgent.Hooks do
  @moduledoc """
  Optional hooks for broadcasting and queuing agent events.

  You can set env config:
    config :ai_rules_agent, hooks: [broadcast: {Mod, :fun, []}, enqueue: {Mod, :fun, []}]
  """

  def broadcast(event) do
    case Application.get_env(:ai_rules_agent, :hooks, [])[:broadcast] do
      {mod, fun, args} -> safe_apply(mod, fun, [event | args])
      _ -> :ok
    end
  end

  def enqueue(job) do
    case Application.get_env(:ai_rules_agent, :hooks, [])[:enqueue] do
      {mod, fun, args} -> safe_apply(mod, fun, [job | args])
      _ -> :ok
    end
  end

  defp safe_apply(mod, fun, args) do
    try do
      apply(mod, fun, args)
    rescue
      _ -> :ok
    end
  end
end
