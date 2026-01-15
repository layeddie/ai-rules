# Run with: elixir test_arcana_ingest.exs

# Add project to code path
Code.append_path("_build/dev/lib")

# Start application
Application.ensure_all_started(:ai_rules_context)

# Test Arcana.ingest
IO.puts("Testing Arcana.ingest...")

content = """
GenServer is a process that holds state and can respond to synchronous and asynchronous messages.
GenServer is perfect for stateful processes like caches, servers, and finite state machines.
"""

case Arcana.ingest(content,
  repo: AiRulesContext.Repo,
  collection: "ai-rules",
  metadata: %{"title" => "GenServer Guide"}
) do
  {:ok, doc} ->
    IO.puts("✅ Ingested document: #{inspect(doc.id)}")
    IO.puts("   Collection: #{inspect(doc.collection_id)}")
    IO.puts("   Chunk count: #{inspect(doc.chunk_count)}")

  {:error, reason} ->
    IO.puts("❌ Failed to ingest: #{inspect(reason)}")
end

IO.puts("\nTesting Arcana.search...")

case Arcana.search("GenServer state management",
  repo: AiRulesContext.Repo,
  collection: "ai-rules",
  limit: 3
) do
  {:ok, results} ->
    IO.puts("✅ Search results:")
    Enum.each(results, fn result ->
      IO.puts("   Score: #{Float.round(result.score * 100, 1)}%")
      IO.puts("   Chunk: #{String.slice(result.chunk.text, 0..100)}...")
    end)

  {:error, reason} ->
    IO.puts("❌ Failed to search: #{inspect(reason)}")
end

IO.puts("\nTest completed!")
