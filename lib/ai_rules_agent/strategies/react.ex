defmodule AiRulesAgent.Strategies.ReAct do
  @moduledoc """
  Minimal ReAct-style strategy.

  Assumptions about `llm_fun`:
  * Receives a map containing at least `:messages`
  * Returns `{:ok, %{content: binary}}` for plain replies, or
    `{:ok, %{tool_call: %{name: binary, args: map()}, content: binary | nil}}` when a tool is requested
  """

  @behaviour AiRulesAgent.Strategy

  @impl true
  def init(ctx, _opts), do: {:ok, %{}, ctx}

  @impl true
  def next(user_msg, history, ctx, llm_fun, tools, _opts, st) do
    messages = history ++ [user_msg]

    with {:ok, response} <- llm_fun.(%{messages: messages, tools: map_tools(tools)}),
         {:ok, action} <- decode_response(response) do
      case action do
        {:reply, content} ->
          {:reply, %{role: :assistant, content: content}, st, ctx}

        {:tool, name, args} ->
          {:tool, name, args, st, ctx}
      end
    else
      {:error, reason} ->
        {:stop, {:llm_error, reason}, st, ctx}
    end
  end

  @impl true
  def handle_tool_result(_tool_name, _tool_args, result, history, ctx, llm_fun, tools, _opts, st) do
    with {:ok, response} <- llm_fun.(%{messages: history, tools: map_tools(tools), tool_result: result}),
         {:ok, action} <- decode_response(response) do
      case action do
        {:reply, content} ->
          {:reply, %{role: :assistant, content: content}, st, ctx}

        {:tool, name, args} ->
          {:tool, name, args, st, ctx}
      end
    else
      {:error, reason} ->
        {:stop, {:llm_error, reason}, st, ctx}
    end
  end

  # -- helpers --

  defp decode_response(%{tool_call: %{name: name, args: args}}) when is_binary(name) do
    {:ok, {:tool, name, args}}
  end

  defp decode_response(%{content: content}) when is_binary(content) do
    {:ok, {:reply, content}}
  end

  defp decode_response(%{"tool_call" => %{"name" => name, "args" => args}}) do
    {:ok, {:tool, name, args}}
  end

  defp decode_response(%{"content" => content}) when is_binary(content) do
    {:ok, {:reply, content}}
  end

  defp decode_response(other), do: {:error, {:unknown_response, other}}

  defp map_tools(tools) do
    tools
    |> Map.keys()
    |> Enum.map(fn name -> %{name: name} end)
  end
end
