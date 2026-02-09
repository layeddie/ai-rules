defmodule AiRulesAgent.Memory do
  @moduledoc """
  Behaviour for pluggable agent memory stores.
  """

  @callback load(id :: term()) :: {:ok, list()} | {:error, term()}
  @callback store(id :: term(), history :: list()) :: :ok | {:error, term()}
end
