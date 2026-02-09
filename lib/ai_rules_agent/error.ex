defmodule AiRulesAgent.Error do
  @moduledoc false

  def render({:missing, key}), do: %{code: "missing_param", message: "missing #{key}"}
  def render({:unknown_provider, p}), do: %{code: "unknown_provider", message: "unknown provider #{inspect(p)}"}
  def render({:invalid_tool_args, reason}), do: %{code: "invalid_tool_args", message: inspect(reason)}
  def render(:llm_not_configured), do: %{code: "llm_not_configured", message: "provider not configured"}
  def render(other) when is_atom(other), do: %{code: Atom.to_string(other), message: Atom.to_string(other)}
  def render(other), do: %{code: "error", message: inspect(other)}
end
