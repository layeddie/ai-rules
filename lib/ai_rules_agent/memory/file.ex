defmodule AiRulesAgent.Memory.File do
  @moduledoc """
  Simple persistent memory using ETS for cache and a file per agent under `priv/ai_memory`.

  Stored format is Erlang term (via :erlang.term_to_binary) for speed and simplicity.
  """

  @behaviour AiRulesAgent.Memory

  @table __MODULE__

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
          case File.read(path) do
            {:ok, bin} ->
              history = :erlang.binary_to_term(bin)
              :ets.insert(@table, {id, history})
              {:ok, history}

            {:error, reason} ->
              {:error, reason}
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

    with :ok <- File.mkdir_p(base_dir()),
         :ok <- File.write(path_for(id), :erlang.term_to_binary(history)) do
      :ok
    end
  end

  defp base_dir do
    Path.join(File.cwd!(), "priv/ai_memory")
  end

  defp path_for(id) do
    safe = :erlang.phash2(id, 1_000_000)
    Path.join(base_dir(), "#{safe}.bin")
  end
end
