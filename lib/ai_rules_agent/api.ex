defmodule AiRulesAgent.API do
  @moduledoc """
  Shared API surface for AI agents (HTTP/stdio). Package-friendly version of the TestProject handler.
  """

  @allowlist_path Path.expand("ai/policies/allowlist.txt", File.cwd!())

  def routes_payload do
    app = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    router = Module.concat([app <> "Web", "Router"])

    routes =
      if Code.ensure_loaded?(router) and function_exported?(router, :__routes__, 0) do
        for r <- router.__routes__() do
          %{
            verb: Map.get(r, :verb),
            path: Map.get(r, :path),
            plug: r |> Map.get(:plug) |> inspect(),
            action: Map.get(r, :plug_opts),
            pipe_through: Map.get(r, :pipe_through)
          }
        end
      else
        []
      end

    %{generated_at: DateTime.utc_now(), router: inspect(router), routes: routes}
  end

  def ash_payload do
    app = Mix.Project.config()[:app]

    modules =
      case :application.get_key(app, :modules) do
        {:ok, mods} -> mods
        _ -> []
      end

    ash_modules =
      modules
      |> Enum.filter(&Code.ensure_loaded?/1)
      |> Enum.filter(&function_exported?(&1, :__ash_resource__, 0))
      |> Enum.map(fn mod ->
        info = mod.__ash_resource__()

        %{
          module: inspect(mod),
          short_name: info.short_name,
          actions: Enum.map(info.actions, fn {name, action} -> %{name: name, type: action.type} end),
          attributes: Enum.map(info.attributes, &Map.take(&1, [:name, :type, :allow_nil]))
        }
      end)

    %{generated_at: DateTime.utc_now(), resources: ash_modules}
  end

  def read_span_payload(path, start_line, end_line) do
    with :ok <- ensure_allowed(path) do
      content = read_span(path, start_line, end_line)
      %{path: path, start: start_line, end: end_line, content: content}
    else
      {:error, reason} -> %{error: reason}
    end
  end

  def patch_payload(path, patch) do
    with :ok <- ensure_allowed(path),
         :ok <- validate_patch(patch),
         {:ok, result} <- apply_patch(path, patch) do
      %{status: "ok", result: result}
    else
      {:error, reason} -> %{error: reason}
    end
  end

  def test_payload(file) do
    with :ok <- ensure_allowed(file) do
      {out, status} = System.cmd("mix", ["test", file], stderr_to_stdout: true)
      %{status: status, output: out}
    else
      {:error, reason} -> %{error: reason}
    end
  end

  def doc_lookup_payload(term) when is_binary(term) do
    sources = ["README.md", "docs/ai-agent.md", "ai/README.md"]

    hits =
      sources
      |> Enum.flat_map(fn file ->
        path = Path.expand(file, File.cwd!())

        if File.exists?(path) do
          path
          |> File.stream!()
          |> Stream.with_index(1)
          |> Stream.filter(fn {line, _i} -> String.contains?(String.downcase(line), String.downcase(term)) end)
          |> Enum.map(fn {line, i} -> %{file: file, line: i, snippet: String.trim(line)} end)
        else
          []
        end
      end)
      |> Enum.take(10)

    %{term: term, hits: hits, note: "simple grep; replace with hexdocs cache later"}
  end

  def start_agent_payload(strategy_name, params) do
    with {:ok, strat_mod} <- resolve_strategy(strategy_name),
         {:ok, llm_fun} <- build_llm_fun(Map.get(params, "provider"), params) do
      attrs =
        [
          strategy: strat_mod,
          llm_fun: llm_fun,
          tools: Map.get(params, "tools", %{}),
          memory: maybe_memory(params),
          memory_id: params["memory_id"]
        ]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      case AiRulesAgent.AgentManager.start_agent(attrs) do
        {:ok, id, pid} ->
          %{status: "ok", id: inspect(id), pid: inspect(pid)}

        {:error, reason} ->
          %{error: AiRulesAgent.Error.render(reason)}
      end
    else
      {:error, reason} -> %{error: AiRulesAgent.Error.render(reason)}
    end
  end

  def stop_agent_payload(id) do
    case AiRulesAgent.AgentManager.stop_agent(id) do
      :ok -> %{status: "ok"}
      {:error, reason} -> %{error: AiRulesAgent.Error.render(reason)}
    end
  end

  def list_agents_payload do
    %{agents: AiRulesAgent.AgentManager.list_agents()}
  end

  defp resolve_strategy("react"), do: {:ok, AiRulesAgent.Strategies.ReAct}
  defp resolve_strategy("cot"), do: {:ok, AiRulesAgent.Strategies.CoT}
  defp resolve_strategy("tot"), do: {:ok, AiRulesAgent.Strategies.TreeOfThought}
  defp resolve_strategy(mod) when is_binary(mod) do
    try do
      {:ok, Module.safe_concat([mod])}
    rescue
      _ -> {:error, :unknown_strategy}
    end
  end

  defp maybe_memory(%{"memory" => "file"}), do: AiRulesAgent.Memory.File
  defp maybe_memory(%{"memory" => "sqlite"}), do: AiRulesAgent.Memory.SQLite
  defp maybe_memory(_), do: nil

  defp build_llm_fun(nil, _params), do: {:ok, fn _ -> {:ok, %{content: "llm not configured"}} end}
  defp build_llm_fun("stub", _params), do: {:ok, fn _ -> {:ok, %{content: "stub"}} end}

  defp build_llm_fun("openai", params) do
    with {:ok, key} <- required(params, "api_key") do
      {:ok,
       AiRulesAgent.Transports.OpenAI.llm_fun(
         model: Map.get(params, "model", "gpt-4o"),
         api_key: key,
         base_url: Map.get(params, "base_url"),
         headers: Map.get(params, "headers", %{})
       )}
    end
  end

  defp build_llm_fun("anthropic", params) do
    with {:ok, key} <- required(params, "api_key") do
      {:ok,
       AiRulesAgent.Transports.Anthropic.llm_fun(
         model: Map.get(params, "model", "claude-3-sonnet"),
         api_key: key,
         base_url: Map.get(params, "base_url"),
         headers: Map.get(params, "headers", %{})
       )}
    end
  end

  defp build_llm_fun("openrouter", params) do
    with {:ok, key} <- required(params, "api_key") do
      {:ok,
       AiRulesAgent.Transports.OpenRouter.llm_fun(
         model: Map.get(params, "model", "openrouter/auto"),
         api_key: key,
         base_url: Map.get(params, "base_url"),
         headers: Map.get(params, "headers", %{})
       )}
    end
  end

  defp build_llm_fun(other, _params), do: {:error, {:unknown_provider, other}}

  defp required(map, key) do
    case Map.get(map, key) do
      nil -> {:error, {:missing, key}}
      v -> {:ok, v}
    end
  end

  # --- helpers ---

  def ensure_allowed(path) do
    abs = Path.expand(path)
    root = File.cwd!()

    allowed =
      @allowlist_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.reject(&String.starts_with?(&1, "#"))
      |> Enum.flat_map(fn glob -> Path.wildcard(Path.expand(Path.join(root, glob))) end)
      |> Enum.map(&Path.expand/1)

    if abs in allowed, do: :ok, else: {:error, "path not allowed"}
  end

  def validate_patch(patch) do
    cond do
      byte_size(patch) > 200_000 -> {:error, "patch too large"}
      String.contains?(patch, "\n@@") -> :ok
      true -> {:error, "patch must be unified diff with hunks"}
    end
  end

  def apply_patch(path, patch) do
    abs = Path.expand(path)
    backup = abs <> ".bak"

    case System.cmd("patch", ["-p0", "-i", "-"], input: patch, cd: File.cwd!()) do
      {out, 0} ->
        if File.exists?(abs), do: File.cp!(abs, backup)
        {:ok, %{output: out, backup: Path.relative_to(backup, File.cwd!())}}

      {out, code} ->
        {:error, "patch failed (#{code}): #{out}"}
    end
  end

  def read_span(path, start_line, end_line) do
    path
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.filter(fn {_line, idx} -> idx >= start_line and idx <= end_line end)
    |> Enum.map_join("", fn {line, _} -> line end)
  end
end
