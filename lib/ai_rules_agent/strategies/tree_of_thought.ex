defmodule AiRulesAgent.Strategies.TreeOfThought do
  @moduledoc """
  Minimal Tree-of-Thought style strategy.

  It generates multiple candidate thoughts, scores them, and then asks the LLM
  to choose a final answer. This is intentionally simple and LLM-agnostic.
  """

  @behaviour AiRulesAgent.Strategy

  @impl true
  def init(ctx, opts) do
    branches = Keyword.get(opts, :branches, 3)
    {:ok, %{branches: branches}, ctx}
  end

  @impl true
  def next(user_msg, history, ctx, llm_fun, _tools, _opts, %{branches: branches} = st) do
    # Step 1: ask for N candidate thoughts
    prompt = [
      %{role: :assistant, content: "Generate #{branches} distinct reasoning paths as bullet points."}
      | history ++ [user_msg]
    ]

    with {:ok, %{content: thoughts}} <- llm_fun.(%{messages: prompt}),
         candidates <- split_lines(thoughts),
         {:ok, best} <- pick_best(candidates, llm_fun, history, user_msg) do
      {:reply, %{role: :assistant, content: best}, st, ctx}
    else
      {:error, reason} -> {:stop, {:llm_error, reason}, st, ctx}
      _ -> {:stop, :tot_failed, st, ctx}
    end
  end

  defp split_lines(text) do
    text
    |> String.split("\n")
    |> Enum.map(&String.trim_leading(&1, "- "))
    |> Enum.reject(&(&1 == ""))
  end

  defp pick_best(candidates, llm_fun, history, user_msg) do
    ranking_prompt = [
      %{role: :assistant, content: "Given these candidate solutions, pick the single best one and answer the user."},
      %{role: :assistant, content: Enum.join(candidates, "\n")},
      user_msg
    ]

    case llm_fun.(%{messages: history ++ ranking_prompt}) do
      {:ok, %{content: content}} -> {:ok, content}
      other -> other
    end
  end
end
