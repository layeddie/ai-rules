defmodule AiRulesAgent.AgentManager do
  @moduledoc """
  Convenience wrapper around the agent supervisor for start/stop/list.
  """

  alias AiRulesAgent.AgentSupervisor

  @registry __MODULE__.Registry

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {Task, :start_link, [fn -> init(opts) end]},
      type: :supervisor
    }
  end

  def init(opts) do
    {:ok, sup} = AgentSupervisor.start_link(name: Keyword.get(opts, :supervisor, AgentSupervisor))
    start_registry()
    Process.put(:agent_manager_sup, sup)
    Process.sleep(:infinity)
  end

  def start_agent(attrs) do
    start_registry()
    sup = ensure_sup()
    {:ok, pid} = AgentSupervisor.start_agent(sup, attrs)
    id = attrs[:id] || pid
    Registry.register(registry_name(), id, pid)
    {:ok, id, pid}
  end

  def stop_agent(id) do
    with [{pid, _}] <- Registry.lookup(registry_name(), id) do
      Process.exit(pid, :normal)
      Registry.unregister(registry_name(), id)
      :ok
    else
      _ -> {:error, :not_found}
    end
  end

  def list_agents do
    Registry.select(registry_name(), [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3"}}]}])
  end

  defp start_registry do
    case Registry.start_link(keys: :unique, name: registry_name()) do
      {:error, {:already_started, _}} -> :ok
      {:ok, _} -> :ok
    end
  end

  defp ensure_sup do
    sup_name = supervisor_name()

    case Process.get(:agent_manager_sup) do
      nil ->
        case AgentSupervisor.start_link(name: sup_name) do
          {:ok, sup} ->
            Process.unlink(sup)
            Process.put(:agent_manager_sup, sup)
            sup

          {:error, {:already_started, pid}} ->
            Process.put(:agent_manager_sup, pid)
            pid
        end

      pid ->
        pid
    end
  end

  defp supervisor_name do
    Application.get_env(:ai_rules_agent, :supervisor_name, AgentSupervisor)
  end

  defp registry_name do
    Application.get_env(:ai_rules_agent, :registry, @registry)
  end
end
