defmodule AiRulesAgent.Strategy do
  @moduledoc """
  Behaviour for agent reasoning strategies.

  A strategy decides what to do after each user message or tool result. It
  returns either a direct reply, a tool invocation, or a stop signal. The
  AgentServer handles tool execution and history wiring.

  This is intentionally small; strategies can call the provided `llm_fun` to
  talk to any model/provider without hard-coding transport concerns.
  """

  @typedoc """
  Message entries preserved in agent history.

  * `:user` — user input
  * `:assistant` — model reply
  * `:tool` — tool results stored as strings for now
  """
  @type message :: %{role: :user | :assistant | :tool, content: String.t(), name?: String.t()}

  @type tool_args :: map()
  @type tool_name :: String.t()
  @type ctx :: map()
  @type llm_fun :: (map() -> {:ok, map()} | {:error, term()})
  @type tools :: %{optional(tool_name()) => (tool_args() -> term())}

  @callback init(ctx(), keyword()) :: {:ok, strategy_state :: term(), ctx()} | {:ok, strategy_state :: term()}

  @callback next(
              user_message :: message(),
              history :: [message()],
              ctx(),
              llm_fun(),
              tools(),
              opts :: keyword(),
              strategy_state :: term()
            ) ::
              {:reply, message(), strategy_state :: term(), ctx()}
              | {:tool, tool_name(), tool_args(), strategy_state :: term(), ctx()}
              | {:stop, term(), strategy_state :: term(), ctx()}

  @callback handle_tool_result(
              tool_name(),
              tool_args(),
              result :: term(),
              history :: [message()],
              ctx(),
              llm_fun(),
              tools(),
              opts :: keyword(),
              strategy_state :: term()
            ) ::
              {:reply, message(), strategy_state :: term(), ctx()}
              | {:tool, tool_name(), tool_args(), strategy_state :: term(), ctx()}
              | {:stop, term(), strategy_state :: term(), ctx()}

  @optional_callbacks handle_tool_result: 9
end
