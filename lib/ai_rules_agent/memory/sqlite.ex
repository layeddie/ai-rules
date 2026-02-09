defmodule AiRulesAgent.Memory.SQLite do
  @moduledoc """
  Lightweight persistent memory using ETS cache and per-id files under `priv/ai_memory_sqlite/`.

  Named SQLite for parity, but implemented via term files to avoid native deps.
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
        path = path_for(id)

        if File.exists?(path) do
          with {:ok, bin} <- File.read(path) do
            history = :erlang.binary_to_term(bin)
            :ets.insert(@table, {id, history})
            {:ok, history}
          end
        else
          {:ok, []}
        end
    end
  end

  @impl true
  def store(id, history) when is_list(history) do
    ensure_started()
    :ets.insert(@table, {id, history})

    :ok = File.mkdir_p(base_dir())
    File.write(path_for(id), :erlang.term_to_binary(history))
  end

  defp base_dir do
    Path.join(File.cwd!(), "priv/ai_memory_sqlite")
  end

  defp path_for(id) do
    safe = :erlang.phash2(id, 1_000_000)
    Path.join(base_dir(), "#{safe}.bin")
  end
end
