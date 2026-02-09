defmodule AiRulesAgent.RAG.MemoryIndex do
  @moduledoc """
  In-memory vector store for small RAG experiments. NOT for production scale.

  Stores {id, text, embedding} tuples in ETS and returns top-k by cosine similarity.
  """

  @table __MODULE__

  def ensure_started do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
        :ok

      _ ->
        :ok
    end
  end

  def upsert(id, text, embedding) when is_list(embedding) do
    ensure_started()
    :ets.insert(@table, {id, text, embedding})
    :ok
  end

  def search(query_embedding, k \\ 3) when is_list(query_embedding) do
    ensure_started()

    :ets.tab2list(@table)
    |> Enum.map(fn {id, text, emb} -> {id, text, cosine(query_embedding, emb)} end)
    |> Enum.sort_by(fn {_id, _text, score} -> -score end)
    |> Enum.take(k)
    |> Enum.map(fn {id, text, score} -> %{id: id, text: text, score: score} end)
  end

  defp cosine(a, b) do
    dot = Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    norm = :math.sqrt(Enum.reduce(a, 0.0, fn x, acc -> acc + x * x end)) * :math.sqrt(Enum.reduce(b, 0.0, fn y, acc -> acc + y * y end))
    if norm == 0, do: 0.0, else: dot / norm
  end
end
