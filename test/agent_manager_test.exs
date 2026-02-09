defmodule AiRulesAgent.AgentManagerTest do
  use ExUnit.Case, async: true

  alias AiRulesAgent.AgentManager
  alias AiRulesAgent.AgentServer
  alias AiRulesAgent.Strategies.ReAct
  alias AiRulesAgent.Memory.File, as: FileMemory

  setup do
    # ensure manager registry is up for tests
    Application.put_env(:ai_rules_agent, :req_recipient, self())
    on_exit(fn -> Application.delete_env(:ai_rules_agent, :req_recipient) end)
  end

  test "start/list/stop agent" do
    {:ok, id, pid} =
      AgentManager.start_agent(strategy: ReAct, llm_fun: fn _ -> {:ok, %{content: "ok"}} end)

    assert is_pid(pid)
    assert [{^id, ^pid}] = AgentManager.list_agents()

    assert :ok = AgentManager.stop_agent(id)
  end

  test "memory file store persists history" do
    mem_id = :test_agent

    {:ok, id, pid} =
      AgentManager.start_agent(
        strategy: ReAct,
        llm_fun: fn _ -> {:ok, %{content: "hi"}} end,
        memory: FileMemory,
        memory_id: mem_id
      )

    assert {:ok, "hi"} = AgentServer.ask(pid, "hello")
    :ok = AgentManager.stop_agent(id)

    {:ok, history} = FileMemory.load(mem_id)
    assert Enum.any?(history, fn m -> m[:content] == "hello" end)
  end
end
