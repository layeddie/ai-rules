defmodule AiRulesAgent.AgentSupervisor do
  @moduledoc """
  Dynamic supervisor for agent servers.

  This keeps agent processes under OTP supervision so callers can start many
  ephemeral agents (per-conversation or per-request) and let the supervisor
  handle restarts.
  """

  use DynamicSupervisor

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new agent under this supervisor.

  `args` are passed through to `AiRulesAgent.AgentServer.start_link/1`.
  """
  def start_agent(supervisor \\ __MODULE__, args) do
    child = {AiRulesAgent.AgentServer, args}
    DynamicSupervisor.start_child(supervisor, child)
  end
end
