defmodule AiRulesAgent.AgentServer do
  @moduledoc """
  GenServer that orchestrates a single agent instance.

  It wires together:
  * `strategy` module implementing `AiRulesAgent.Strategy`
  * `llm_fun` callback for model calls (transport-agnostic)
  * `tools` map of tool_name => (args -> result)
  * `ctx` (arbitrary map) carried through strategy calls
  * bounded step loop (`max_steps`, default 5)

  Public API is synchronous for now (`ask/3`). The strategy decides whether to
  reply directly or invoke tools; tool calls execute inside this process to
  keep state consistent.
  """

  use GenServer

  @type t :: pid()

  defstruct strategy: nil,
            strategy_state: nil,
            llm_fun: nil,
            tools: %{},
            stream_cb: nil,
            ctx: %{},
            history: [],
            max_steps: 5,
            memory: nil,
            memory_id: nil

  @doc """
  Start an agent server.

  Required options:
  * `:strategy` — module implementing `AiRulesAgent.Strategy`
  * `:llm_fun` — function `map -> {:ok, map()} | {:error, term()}`

  Optional:
  * `:tools` — map of tool name => (args -> result)
  * `:ctx` — map passed to the strategy
  * `:strategy_opts` — forwarded to `strategy.init/2`
  * `:max_steps` — loop guard (default 5)
  * `:name` — GenServer name
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name, nil)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Ask the agent a user message. Returns:

  * `{:ok, reply}` when the strategy produced a final reply
  * `{:stop, reason}` if the strategy requested stop
  * `{:error, reason}` for unknown tools or step overflow
  """
  def ask(agent \\ __MODULE__, message, opts \\ []) when is_binary(message) do
    GenServer.call(agent, {:ask, message, opts}, Keyword.get(opts, :timeout, 30_000))
  end

  @doc """
  Read current history (user/assistant/tool messages).
  """
  def history(agent \\ __MODULE__) do
    GenServer.call(agent, :history)
  end

  # -- GenServer callbacks --

  @impl true
  def init(opts) do
    strategy = Keyword.fetch!(opts, :strategy)
    llm_fun = Keyword.fetch!(opts, :llm_fun)
    tools = normalize_tools(Keyword.get(opts, :tools, %{}))
    stream_cb = Keyword.get(opts, :stream, nil)
    ctx = Keyword.get(opts, :ctx, %{})
    strategy_opts = Keyword.get(opts, :strategy_opts, [])
    max_steps = Keyword.get(opts, :max_steps, 5)
    memory = Keyword.get(opts, :memory)
    memory_id = Keyword.get(opts, :memory_id)

    {:ok, strategy_state, ctx} = strategy.init(ctx, strategy_opts)

    history =
      case {memory, memory_id} do
        {mod, id} when not is_nil(mod) and not is_nil(id) ->
          case mod.load(id) do
            {:ok, hist} -> hist
            _ -> []
          end

        _ ->
          []
      end

    state = %__MODULE__{
      strategy: strategy,
      strategy_state: strategy_state,
      llm_fun: llm_fun,
      tools: tools,
      stream_cb: stream_cb,
      ctx: ctx,
      history: history,
      max_steps: max_steps,
      memory: memory,
      memory_id: memory_id
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:history, _from, state) do
    {:reply, state.history, state}
  end

  @impl true
  def handle_call({:ask, message, opts}, _from, state) do
    user_msg = %{role: :user, content: message}
    state = %{state | history: state.history ++ [user_msg]}

    case step(:next, user_msg, state, state.max_steps, opts) do
      {:ok, reply_msg, new_state} ->
        {:reply, {:ok, reply_msg.content}, new_state}

      {:stop, reason, new_state} ->
        {:reply, {:stop, reason}, new_state}

      {:error, reason, new_state} ->
        {:reply, {:error, reason}, new_state}
    end
  end

  # -- internals --

  defp step(_kind, _trigger_msg, state, 0, _opts), do: {:error, :max_steps, state}

  defp step(kind, trigger_msg, state, remaining, opts) do
    call =
      case kind do
        :next -> :next
        :handle_tool_result -> :handle_tool_result
      end

    result =
      case {call, function_exported?(state.strategy, call, arity(call))} do
        {:handle_tool_result, false} ->
      {:reply, %{role: :assistant, content: inspect(trigger_msg)}, state.strategy_state, state.ctx}

        _ ->
          case call do
            :next ->
              apply(state.strategy, :next, [
                trigger_msg,
                state.history,
                state.ctx,
                state.llm_fun,
                state.tools,
                opts,
                state.strategy_state
              ])

            :handle_tool_result ->
              %{tool_name: tool_name, tool_args: tool_args, tool_result: tool_result} = trigger_msg

              apply(state.strategy, :handle_tool_result, [
                tool_name,
                tool_args,
                tool_result,
                state.history,
                state.ctx,
                state.llm_fun,
                state.tools,
                opts,
                state.strategy_state
              ])
          end
      end

    case result do
      {:reply, msg, strategy_state, ctx} ->
        new_state =
          state
          |> put_strategy(strategy_state, ctx)
          |> push_history(msg)
          |> maybe_stream(msg)

        {:ok, msg, new_state}

      {:tool, name, args, strategy_state, ctx} ->
        with {:ok, tool} <- fetch_tool(state.tools, name),
             :ok <- validate_tool_args(tool, args),
             {:ok, tool_result} <- safe_call_tool(tool.fun, args) do
          tool_msg = %{role: :tool, name?: name, content: inspect(tool_result)}

          new_state =
            state
            |> put_strategy(strategy_state, ctx)
            |> push_history(tool_msg)

          step(:handle_tool_result, %{tool_name: name, tool_args: args, tool_result: tool_result}, new_state, remaining - 1, opts)
        else
          {:error, reason} ->
            new_state = put_strategy(state, strategy_state, ctx)
            {:error, reason, new_state}
        end

      {:stop, reason, strategy_state, ctx} ->
        new_state = put_strategy(state, strategy_state, ctx)
        {:stop, reason, new_state}
    end
  end

  defp fetch_tool(tools, name) do
    case Map.fetch(tools, name) do
      {:ok, %{fun: fun} = tool} when is_function(fun, 1) -> {:ok, tool}
      {:ok, _} -> {:error, {:invalid_tool_fun, name}}
      :error -> {:error, {:unknown_tool, name}}
    end
  end

  defp safe_call_tool(fun, args) do
    try do
      {:ok, fun.(args)}
    rescue
      e -> {:error, {:tool_error, e}}
    catch
      kind, reason -> {:error, {:tool_throw, {kind, reason}}}
    end
  end

  defp push_history(state, msg), do: %{state | history: state.history ++ [msg]}

  defp put_strategy(state, strategy_state, ctx) do
    new_state = %{state | strategy_state: strategy_state, ctx: ctx}
    persist_history(new_state)
    new_state
  end

  defp persist_history(%{memory: nil} = state), do: state

  defp persist_history(%{memory: _mod, memory_id: nil} = state), do: state

  defp persist_history(%{memory: mod, memory_id: id, history: history} = state) do
    _ = mod.store(id, history)
    state
  end

  defp maybe_stream(%{stream_cb: nil} = state, _msg), do: state

  defp maybe_stream(%{stream_cb: cb} = state, msg) when is_function(cb, 1) do
    try do
      cb.(msg)
    rescue
      _ -> :ok
    end

    state
  end

  defp normalize_tools(map) when is_map(map) do
    Map.new(map, fn
      {name, %{fun: _fun} = tool} ->
        {name,
         tool
         |> maybe_build_schema()
         |> Map.update(:schema, nil, &compile_schema/1)}

      {name, fun} when is_function(fun, 1) ->
        {name, %{fun: fun, schema: nil}}
    end)
  end

  defp normalize_tools(list) when is_list(list) do
    Enum.into(list, %{}, fn %{name: name, fun: _fun} = t ->
      {name,
       t
       |> maybe_build_schema()
       |> Map.update(:schema, nil, &compile_schema/1)}
    end)
  end

  defp validate_tool_args(%{schema: nil}, _args), do: :ok

  defp validate_tool_args(%{schema: schema}, args) do
    case ExJsonSchema.Validator.validate(schema, args) do
      :ok -> :ok
      {:error, reason} -> {:error, {:invalid_tool_args, reason}}
    end
  end

  defp compile_schema(nil), do: nil
  defp compile_schema(%ExJsonSchema.Schema.Root{} = s), do: s

  defp compile_schema(map) when is_map(map) do
    ExJsonSchema.Schema.resolve(map)
  end

  defp maybe_build_schema(%{schema_spec: spec} = tool) when not is_nil(spec) do
    schema = AiRulesAgent.ToolSchema.from_spec(spec)
    Map.put(tool, :schema, schema)
  end

  defp maybe_build_schema(tool), do: tool

  defp arity(:next), do: 7
  defp arity(:handle_tool_result), do: 9
end
