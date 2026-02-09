defmodule AiRulesAgent.RAG.PgVectorStore do
  @moduledoc """
  Minimal pgvector-backed store for small RAG lookups.

  Requires:
    - Postgrex dependency (optional in mix.exs)
    - DB with pgvector extension enabled and a table:
      CREATE TABLE ai_vectors (id text primary key, embedding vector, content text);
  """

  @default_table "ai_vectors"

  def new(opts) do
    %{
      conn: Keyword.fetch!(opts, :conn),
      table: Keyword.get(opts, :table, @default_table),
      dimensions: Keyword.get(opts, :dimensions, 1536)
    }
  end

  def upsert(store, id, embedding, content) when is_list(embedding) do
    sql = """
    INSERT INTO #{store.table} (id, embedding, content)
    VALUES ($1, $2, $3)
    ON CONFLICT (id) DO UPDATE SET embedding = EXCLUDED.embedding, content = EXCLUDED.content
    """

    Postgrex.query(store.conn, sql, [id, to_pgvector(store, embedding), content])
  end

  def search(store, embedding, k \\ 3) do
    sql = """
    SELECT id, content, 1 - (embedding <=> $1) AS score
    FROM #{store.table}
    ORDER BY embedding <=> $1
    LIMIT $2
    """

    case Postgrex.query(store.conn, sql, [to_pgvector(store, embedding), k]) do
      {:ok, %Postgrex.Result{rows: rows}} ->
        {:ok, Enum.map(rows, fn [id, content, score] -> %{id: id, text: content, score: score} end)}

      other ->
        other
    end
  end

  defp to_pgvector(store, list) do
    "{" <> Enum.join(Enum.map(list, &to_string/1), ",") <> "}"
  end
end
