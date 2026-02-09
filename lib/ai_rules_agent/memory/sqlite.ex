defmodule AiRulesAgent.Memory.SQLite do
  @moduledoc """
  SQLite-backed memory store with ETS cache.
  """

  @behaviour AiRulesAgent.Memory

  @table __MODULE__.Cache

  def start_link(opts \\ []) do
    Task.start_link(fn ->
      ensure_started(opts)
      Process.sleep(:infinity)
    end)
  end

  def ensure_started(opts \\ []) do
    maybe_start_cache()
    db = opts |> Keyword.get(:db_path, default_db())
    {:ok, conn} = Exqlite.Sqlite3.open(db)
    :ok = Exqlite.Sqlite3.execute(conn, "CREATE TABLE IF NOT EXISTS memories (id TEXT PRIMARY KEY, blob BLOB)")
    Process.put({__MODULE__, :conn}, conn)
    :ok
  end

  @impl true
  def load(id) do
    ensure_started()

    case :ets.lookup(@table, id) do
      [{^id, history}] ->
        {:ok, history}

      [] ->
        conn = conn!()
        case Exqlite.Sqlite3.prepare(conn, "SELECT blob FROM memories WHERE id = ?1") do
          {:ok, stmt} ->
            :ok = Exqlite.Sqlite3.bind(conn, stmt, [to_string(id)])
            result = Exqlite.Sqlite3.step(conn, stmt)
            Exqlite.Sqlite3.release(conn, stmt)

            case result do
              {:row, [blob]} ->
                history = :erlang.binary_to_term(blob)
                :ets.insert(@table, {id, history})
                {:ok, history}

              :done ->
                {:ok, []}
            end

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @impl true
  def store(id, history) when is_list(history) do
    ensure_started()
    :ets.insert(@table, {id, history})
    conn = conn!()
    blob = :erlang.term_to_binary(history)

    with {:ok, stmt} <- Exqlite.Sqlite3.prepare(conn, "REPLACE INTO memories (id, blob) VALUES (?1, ?2)") do
      :ok = Exqlite.Sqlite3.bind(conn, stmt, [to_string(id), blob])
      _ = Exqlite.Sqlite3.step(conn, stmt)
      Exqlite.Sqlite3.release(conn, stmt)
      :ok
    end
  end

  defp default_db do
    Path.join(File.cwd!(), "priv/ai_memory.sqlite3")
  end

  defp conn! do
    Process.get({__MODULE__, :conn}) || raise "memory sqlite not started"
  end

  defp maybe_start_cache do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
      _ -> :ok
    end
  end
end
