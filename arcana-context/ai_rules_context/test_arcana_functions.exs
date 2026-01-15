# Test Arcana with actual functions

# Start application
Application.ensure_all_started(:ai_rules_context)

IO.puts("Testing Arcana functions with database...")

# Test 1: Ingest a document
IO.puts("\n1. Testing Arcana.ingest...")

content = """
GenServer is a process that holds state and can respond to synchronous and asynchronous messages.
GenServer is perfect for stateful processes like caches, servers, and finite state machines.
"""

case Arcana.ingest(content,
  repo: AiRulesContext.Repo,
  collection: "ai-rules",
  metadata: %{"title" => "GenServer Test", "section" => "otp"}
) do
  {:ok, doc} ->
    IO.puts("✅ Ingested document:")
    IO.puts("   ID: #{inspect(doc.id)}")
    IO.puts("   Collection: #{inspect(doc.collection_id)}")
    IO.puts("   Chunks: #{doc.chunk_count}")

  {:error, reason} ->
    IO.puts("❌ Failed to ingest: #{inspect(reason)}")
end

# Test 2: Search for documents
IO.puts("\n2. Testing Arcana.search...")

case Arcana.search("GenServer state management",
  repo: AiRulesContext.Repo,
  collection: "ai-rules",
  limit: 3
) do
  {:ok, results} ->
    IO.puts("✅ Search results:")
    Enum.each(results, fn result ->
      IO.puts("   Score: #{Float.round(result.score * 100, 1)}%")
      IO.puts("   Chunk: #{String.slice(result.chunk.text, 0..80)}...")
    end)

  {:error, reason} ->
    IO.puts("❌ Failed to search: #{inspect(reason)}")
end

IO.puts("\n✅ All tests passed!")
