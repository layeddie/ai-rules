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
    sup_name = Keyword.get(opts, :supervisor, supervisor_name())
    reg = Keyword.get(opts, :registry, registry_name())
    start_registry(reg)
    ensure_sup(sup_name)
    Process.sleep(:infinity)
  end

  def start_agent(attrs, opts \\ []) do
    opts = normalize_opts(opts)
    reg = Keyword.get(opts, :registry, registry_name())
    sup_name = Keyword.get(opts, :supervisor, supervisor_name())
    start_registry(reg)
    sup = ensure_sup(sup_name)
    {:ok, pid} = AgentSupervisor.start_agent(sup, attrs)
    id = attrs[:id] || pid
    Registry.register(reg, id, pid)
    {:ok, id, pid}
  end

  def stop_agent(id, opts \\ []) do
    opts = normalize_opts(opts)
    reg = Keyword.get(opts, :registry, registry_name())

    with :ok <- start_registry(reg),
         [{pid, _}] <- Registry.lookup(reg, id) do
      ref = Process.monitor(pid)
      Process.exit(pid, :normal)
      receive do
        {:DOWN, ^ref, :process, ^pid, _} -> :ok
      after
        50 -> :ok
      end
      Registry.unregister(reg, id)
      :ok
    else
      _ -> {:error, :not_found}
    end
  end

  def list_agents(opts \\ []) do
    opts = normalize_opts(opts)
    reg = Keyword.get(opts, :registry, registry_name())
    start_registry(reg)
    Registry.select(reg, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3"}}]}])
  end

  defp start_registry(reg) do
    case Registry.start_link(keys: :unique, name: reg) do
      {:ok, pid} ->
        Process.unlink(pid)
        :ok

      {:error, {:already_started, _}} -> :ok
      {:error, {:already_registered, _}} -> :ok
    end
  end

  defp ensure_sup(sup_name) do
    case Process.get({:agent_manager_sup, sup_name}) do
      nil ->
        case AgentSupervisor.start_link(name: sup_name) do
          {:ok, sup} ->
            Process.unlink(sup)
            Process.put({:agent_manager_sup, sup_name}, sup)
            sup

          {:error, {:already_started, pid}} ->
            Process.put({:agent_manager_sup, sup_name}, pid)
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

  defp normalize_opts(opts) when is_list(opts), do: opts
  defp normalize_opts(%{} = map), do: Map.to_list(map)
end
