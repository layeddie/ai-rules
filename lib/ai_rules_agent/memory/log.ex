defmodule AiRulesAgent.Memory.Log do
  @moduledoc """
  Append-only log-backed memory with ETS cache.

  Each agent history is stored at `priv/ai_log/<hash>.log` as newline-delimited
  Erlang term binaries. On load, we stream and rebuild history; on store, we
  append. A simple compaction keeps only the last `:max_entries` (default 200).
  """

  @behaviour AiRulesAgent.Memory

  @table __MODULE__.Cache

  def ensure_started do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
        :ok

      _ ->
        :ok
    end
  end

  @impl true
  def load(id) do
    ensure_started()

    case :ets.lookup(@table, id) do
      [{^id, history}] ->
        {:ok, history}

      [] ->
        history =
          path_for(id)
          |> stream_terms()
          |> Enum.to_list()

        :ets.insert(@table, {id, history})
        {:ok, history}
    end
  end

  @impl true
  def store(id, history) when is_list(history) do
    ensure_started()
    :ets.insert(@table, {id, history})
    :ok = File.mkdir_p(base_dir())
    path = path_for(id)
    line = :erlang.term_to_binary(history) |> Base.encode64()
    File.write!(path, line <> "\n", [:append])
    compact(id, history, path)
  end

  defp stream_terms(path) do
    if File.exists?(path) do
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line -> line |> Base.decode64!() |> :erlang.binary_to_term() end)
      |> Stream.take(-1) # take last entry
      |> Stream.concat([])
    else
      []
      |> Stream.concat()
    end
  end

  defp compact(id, history, path) do
    max_entries = Application.get_env(:ai_rules_agent, :memory_log_max_entries, 200)

    if length(history) > max_entries do
      trimmed = Enum.take(history, -max_entries)
      File.write!(path, Base.encode64(:erlang.term_to_binary(trimmed)) <> "\n")
      :ets.insert(@table, {id, trimmed})
    end
  end

  defp base_dir do
    Path.join(File.cwd!(), "priv/ai_log")
  end

  defp path_for(id) do
    hash = :erlang.phash2(id, 1_000_000)
    Path.join(base_dir(), "#{hash}.log")
  end
end
