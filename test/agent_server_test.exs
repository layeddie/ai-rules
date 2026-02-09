defmodule AiRulesAgent.AgentServerTest do
  use ExUnit.Case, async: true

  alias AiRulesAgent.AgentServer
  alias AiRulesAgent.AgentSupervisor
  alias AiRulesAgent.Strategies.ReAct

  describe "ask/2 with ReAct" do
    test "returns direct reply" do
      llm_fun = fn _ -> {:ok, %{content: "hi there"}} end

      {:ok, pid} =
        AgentServer.start_link(strategy: ReAct, llm_fun: llm_fun, tools: %{}, max_steps: 3)

      assert {:ok, "hi there"} = AgentServer.ask(pid, "hello")
      assert [%{role: :user, content: "hello"}, %{role: :assistant, content: "hi there"}] =
               AgentServer.history(pid)
    end

    test "calls tool then replies" do
      # first call: request tool
      # second call (with tool_result): craft final answer
      llm_fun = fn
        %{tool_result: _} -> {:ok, %{content: "done"}}
        _ -> {:ok, %{tool_call: %{name: "echo", args: %{"msg" => "ok"}}}}
      end

      tools = %{"echo" => fn %{"msg" => msg} -> msg end}

      {:ok, pid} =
        AgentServer.start_link(strategy: ReAct, llm_fun: llm_fun, tools: tools, max_steps: 3)

      assert {:ok, "done"} = AgentServer.ask(pid, "hi")

      # history should include user, tool, assistant
      history = AgentServer.history(pid)
      assert [%{role: :user, content: "hi"}, %{role: :tool, content: "\"ok\""}, %{role: :assistant, content: "done"}] = history
    end
  end

  describe "bounded loop guard" do
    defmodule LoopStrategy do
      @behaviour AiRulesAgent.Strategy

      @impl true
      def init(ctx, _opts), do: {:ok, %{}, ctx}

      @impl true
      def next(_msg, _history, ctx, _llm, _tools, _opts, st) do
        {:tool, "noop", %{}, st, ctx}
      end

      @impl true
      def handle_tool_result(_name, _args, _result, _history, ctx, _llm, _tools, _opts, st) do
        {:tool, "noop", %{}, st, ctx}
      end
    end

    test "stops when max_steps exceeded" do
      tools = %{"noop" => fn _ -> :ok end}
      {:ok, pid} =
        AgentServer.start_link(strategy: LoopStrategy, llm_fun: fn _ -> {:ok, %{content: ""}} end, tools: tools, max_steps: 2)

      assert {:error, :max_steps} = AgentServer.ask(pid, "go")
    end
  end

  describe "supervisor helper" do
    test "starts agents under DynamicSupervisor" do
      {:ok, sup} = AgentSupervisor.start_link(name: :"sup_#{System.unique_integer()}")
      {:ok, pid} =
        AgentSupervisor.start_agent(sup, strategy: ReAct, llm_fun: fn _ -> {:ok, %{content: "ok"}} end)

      assert Process.alive?(pid)
      assert {:ok, "ok"} = AgentServer.ask(pid, "hi")
    end
  end

  describe "openai transport helper" do
    test "serialises messages and decodes tool calls" do
      defmodule ReqStub do
        def post(url: _u, headers: _h, json: body) do
          recipient = Application.get_env(:ai_rules_agent, :req_recipient, self())
          send(recipient, {:body, body})

          msgs = Map.get(body, :messages) || Map.get(body, "messages", [])

          has_tool_message? =
            msgs
            |> Enum.any?(fn m -> Map.get(m, :role) == "tool" or Map.get(m, "role") == "tool" end)

          if has_tool_message? do
            {:ok,
             %Req.Response{
               status: 200,
               body: %{
                 "choices" => [
                   %{
                     "message" => %{"content" => "hi"}
                   }
                 ]
               }
             }}
          else
            {:ok,
             %Req.Response{
               status: 200,
               body: %{
                 "choices" => [
                   %{
                     "message" => %{
                       "tool_calls" => [
                         %{
                           "function" => %{
                             "name" => "echo",
                             "arguments" => ~s({\"msg\":\"hi\"})
                           }
                         }
                       ],
                       "content" => nil
                     }
                   }
                 ]
               }
             }}
          end
        end
      end

      llm_fun =
        AiRulesAgent.Transports.OpenAI.llm_fun(model: "gpt-4.1", api_key: "test", req: ReqStub)

      Application.put_env(:ai_rules_agent, :req_recipient, self())
      on_exit(fn -> Application.delete_env(:ai_rules_agent, :req_recipient) end)

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: %{"echo" => fn %{"msg" => msg} -> msg end},
          max_steps: 2
        )

      assert {:ok, "hi"} = AgentServer.ask(pid, "say hi")

      assert_receive {:body, body}, 50
      assert %{"model" => "gpt-4.1"} = Map.new(body, fn {k, v} -> {to_string(k), v} end)
    end
  end

  describe "anthropic transport helper" do
    test "decodes tool call" do
      defmodule AnthropicStub do
        def post(url: _u, headers: _h, json: body) do
          recipient = Application.get_env(:ai_rules_agent, :req_recipient, self())
          send(recipient, {:body, body})

          msgs = Map.get(body, "messages") || []
          tool_seen? = Enum.any?(msgs, fn m -> Map.get(m, "role") == "tool" end)

          resp =
            if tool_seen? do
              %{"content" => [%{"type" => "text", "text" => "2"}]}
            else
              %{
                "content" => [
                  %{"type" => "tool_use", "name" => "calc", "input" => %{"a" => 1}}
                ]
              }
            end

          {:ok, %Req.Response{status: 200, body: resp}}
        end
      end

      llm_fun = AiRulesAgent.Transports.Anthropic.llm_fun(model: "claude-3", api_key: "x", req: AnthropicStub)
      Application.put_env(:ai_rules_agent, :req_recipient, self())
      on_exit(fn -> Application.delete_env(:ai_rules_agent, :req_recipient) end)

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: %{"calc" => fn %{"a" => a} -> a + 1 end},
          max_steps: 2
        )

      assert {:ok, "2"} = AgentServer.ask(pid, "add 1")
      assert_receive {:body, %{"model" => "claude-3"}}, 50
    end
  end

  describe "CoT strategy" do
    test "returns assistant content with system prompt prefixed" do
      llm_fun = fn %{messages: messages} ->
        # ensure prompt is first
        [%{content: prompt} | _] = messages
        {:ok, %{content: prompt <> " done"}}
      end

      {:ok, pid} =
        AgentServer.start_link(
          strategy: AiRulesAgent.Strategies.CoT,
          strategy_opts: [system_prompt: "Think slow."],
          llm_fun: llm_fun
        )

      assert {:ok, "Think slow. done"} = AgentServer.ask(pid, "ping")
    end
  end

  describe "openrouter transport helper" do
    test "routes through openrouter helper" do
      defmodule ORStub do
        def post(url: _u, headers: _h, json: body) do
          recipient = Application.get_env(:ai_rules_agent, :req_recipient, self())
          send(recipient, {:body, body})

          {:ok,
           %Req.Response{
             status: 200,
             body: %{
               "choices" => [
                 %{
                   "message" => %{
                     "content" => "hi"
                   }
                 }
               ]
             }
           }}
        end
      end

      llm_fun = AiRulesAgent.Transports.OpenRouter.llm_fun(model: "openrouter/model", api_key: "x", req: ORStub)
      Application.put_env(:ai_rules_agent, :req_recipient, self())
      on_exit(fn -> Application.delete_env(:ai_rules_agent, :req_recipient) end)

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: %{},
          max_steps: 1
        )

      assert {:ok, "hi"} = AgentServer.ask(pid, "hello")
      assert_receive {:body, body}, 50
      assert "openrouter/model" == Map.get(body, "model") || Map.get(body, :model)
    end
  end

  describe "provider failover" do
    test "falls back when first provider errors" do
      bad_fun = fn _ -> {:error, :boom} end
      good_fun = fn _ -> {:ok, %{content: "ok"}} end

      chain = fn payload ->
        Enum.reduce_while([bad_fun, good_fun], {:error, :none}, fn fun, _ ->
          case fun.(payload) do
            {:ok, res} -> {:halt, {:ok, res}}
            {:error, _} = err -> {:cont, err}
          end
        end)
      end

      tools = %{}

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: chain,
          tools: tools,
          max_steps: 1
        )

      assert {:ok, "ok"} = AgentServer.ask(pid, "hello")
    end
  end

  describe "tree of thought strategy" do
    test "chooses best candidate" do
      llm_fun = fn %{messages: msgs} ->
        case Enum.find(msgs, fn m -> m[:content] =~ "bullet" end) do
          nil ->
            {:ok, %{content: "best"}}

          _ ->
            {:ok, %{content: "- first\n- second\n- best"}}
        end
      end

      {:ok, pid} =
        AgentServer.start_link(
          strategy: AiRulesAgent.Strategies.TreeOfThought,
          llm_fun: llm_fun,
          strategy_opts: [branches: 3]
        )

      assert {:ok, "best"} = AgentServer.ask(pid, "solve")
    end
  end

  describe "tool schema validation" do
    test "rejects invalid args" do
      schema = %{
        "type" => "object",
        "required" => ["n"],
        "properties" => %{"n" => %{"type" => "integer"}}
      }

      llm_fun = fn _ -> {:ok, %{tool_call: %{name: "double", args: %{"n" => "bad"}}}} end

      tools = %{
        "double" => %{fun: fn %{"n" => n} -> n * 2 end, schema: schema}
      }

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: tools,
          max_steps: 1
        )

      assert {:error, {:invalid_tool_args, _}} = AgentServer.ask(pid, "go")
    end

    test "builds schema from spec helper" do
      llm_fun = fn
        %{tool_result: _} -> {:ok, %{content: "3"}}
        _ -> {:ok, %{tool_call: %{name: "add", args: %{"a" => 1, "b" => 2}}}}
      end

      tools = %{
        "add" => %{
          fun: fn %{"a" => a, "b" => b} -> a + b end,
          schema_spec: %{a: :integer, b: :integer}
        }
      }

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: tools,
          max_steps: 2
        )

      assert {:ok, "3"} = AgentServer.ask(pid, "add")
    end

    test "stream callback receives messages" do
      llm_fun = fn
        %{tool_result: _} -> {:ok, %{content: "done"}}
        _ -> {:ok, %{tool_call: %{name: "noop", args: %{}}}}
      end

      parent = self()

      tools = %{"noop" => fn _ -> "ok" end}

      {:ok, pid} =
        AgentServer.start_link(
          strategy: ReAct,
          llm_fun: llm_fun,
          tools: tools,
          stream: fn msg -> send(parent, {:stream, msg}) end,
          max_steps: 2
        )

      assert {:ok, "done"} = AgentServer.ask(pid, "hi")
      assert_receive {:stream, %{role: :tool}}, 200
      assert_receive {:stream, %{role: :assistant, content: "done"}}, 100
    end
  end
end
