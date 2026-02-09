defmodule AiRulesAgent.Strategies.CoT do
  @moduledoc """
  Simple Chain-of-Thought style strategy.

  It never calls tools; it just forwards the full message history to `llm_fun`
  with an optional `:system_prompt` hint, returning the model content directly.
  """

  @behaviour AiRulesAgent.Strategy

  @impl true
  def init(ctx, opts) do
    system_prompt = Keyword.get(opts, :system_prompt, "Think step by step before answering.")
    {:ok, %{system_prompt: system_prompt}, ctx}
  end

  @impl true
  def next(user_msg, history, ctx, llm_fun, _tools, _opts, %{system_prompt: prompt} = st) do
    messages = [%{role: :assistant, content: prompt} | history] ++ [user_msg]

    case llm_fun.(%{messages: messages}) do
      {:ok, %{content: content}} -> {:reply, %{role: :assistant, content: content}, st, ctx}
      {:ok, other} -> {:stop, {:unexpected, other}, st, ctx}
      {:error, reason} -> {:stop, {:llm_error, reason}, st, ctx}
    end
  end
end
