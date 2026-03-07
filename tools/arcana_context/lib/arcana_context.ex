defmodule ArcanaContext do
  @moduledoc """
  Public helpers for Arcana-backed documentation retrieval.
  """

  def ingest(opts \\ []), do: ArcanaContext.Docs.ingest_ai_rules_docs(opts)
  def search(query, opts \\ []), do: ArcanaContext.Docs.search(query, opts)
end
