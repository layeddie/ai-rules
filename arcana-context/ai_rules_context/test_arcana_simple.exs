# Test Arcana directly from Elixir module

# Start application
Application.ensure_all_started(:ai_rules_context)

IO.puts("Testing Arcana basic functions...")

# Test 1: Check if Arcana module is available
case Code.ensure_loaded?(Arcana) do
  true ->
    IO.puts("✅ Arcana module is available")

  false ->
    IO.puts("❌ Arcana module not found")
end

# Test 2: Try loading Arcana
try do
  Code.require_file("deps/arcana/lib/arcana.ex")
  IO.puts("✅ Arcana loaded successfully")

rescue
  e in [Code.LoadError] ->
    IO.puts("❌ Failed to load Arcana: #{inspect(e)}")
end

IO.puts("\nTest completed!")
