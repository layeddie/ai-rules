defmodule AiRulesAgent.TestHelper do
  @moduledoc """
  Lightweight fakes for transports and tools to simplify agent tests.
  """

  def fake_llm(reply) when is_binary(reply) do
    fn _ -> {:ok, %{content: reply}} end
  end

  def fake_tool_call(name, args \\ %{}) do
    fn _ -> {:ok, %{tool_call: %{name: name, args: args}}} end
  end

  def fake_chain(funs) when is_list(funs) do
    fn payload ->
      Enum.reduce_while(funs, {:error, :none}, fn fun, _ ->
        case fun.(payload) do
          {:ok, res} -> {:halt, {:ok, res}}
          {:error, _} = err -> {:cont, err}
        end
      end)
    end
  end

  def noop_tool, do: %{"noop" => fn _ -> "ok" end}

  def fake_embedding(vec) do
    fn _texts, _opts -> {:ok, [vec]} end
  end
end
