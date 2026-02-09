defmodule AiRulesAgent.AgentManagerTest do
  use ExUnit.Case, async: true

  alias AiRulesAgent.AgentManager
  alias AiRulesAgent.AgentServer
  alias AiRulesAgent.Strategies.ReAct
  alias AiRulesAgent.Memory.File, as: FileMemory

  setup do
    Process.flag(:trap_exit, true)
    reg = :"agent_registry_#{System.unique_integer()}"
    sup_name = :"agent_sup_#{System.unique_integer()}"
    [registry: reg, supervisor: sup_name]
  end

  test "start/list/stop agent", ctx do
    {:ok, id, pid} =
      AgentManager.start_agent(
        [strategy: ReAct, llm_fun: fn _ -> {:ok, %{content: "ok"}} end],
        ctx
      )

    assert is_pid(pid)
    assert [{^id, ^pid}] = AgentManager.list_agents(ctx)

    assert :ok = AgentManager.stop_agent(id, ctx)
  end

  test "memory file store persists history", ctx do
    mem_id = :test_agent

    {:ok, id, pid} =
      AgentManager.start_agent(
        [
          strategy: ReAct,
          llm_fun: fn _ -> {:ok, %{content: "hi"}} end,
          memory: FileMemory,
          memory_id: mem_id
        ],
        ctx
      )

    assert {:ok, "hi"} = AgentServer.ask(pid, "hello")
    :ok = AgentManager.stop_agent(id, ctx)

    {:ok, history} = FileMemory.load(mem_id)
    assert Enum.any?(history, fn m -> m[:content] == "hello" end)
  end
end
