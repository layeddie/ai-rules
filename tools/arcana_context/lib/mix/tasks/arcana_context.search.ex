defmodule Mix.Tasks.ArcanaContext.Search do
  use Mix.Task

  @shortdoc "Search ai-rules docs indexed by Arcana"

  @switches [
    collection: :string,
    limit: :integer
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    query = Enum.join(positional, " ") |> String.trim()

    if query == "" do
      Mix.raise(
        "Usage: mix arcana_context.search \"query\" [--limit 8] [--collection ai_rules_docs]"
      )
    end

    results =
      ArcanaContext.Docs.search(
        query,
        collection: opts[:collection] || ArcanaContext.Docs.default_collection(),
        limit: opts[:limit] || 8
      )

    Enum.with_index(results, 1)
    |> Enum.each(fn {result, idx} ->
      Mix.shell().info("#{idx}. #{format_result(result)}")
    end)
  end

  defp format_result(result) when is_map(result) do
    text =
      result
      |> Map.get(:text, "")
      |> to_string()
      |> String.replace(~r/\s+/, " ")
      |> String.slice(0, 220)

    source =
      result
      |> Map.get(:metadata, %{})
      |> Map.get("source_path", "unknown source")

    score = Map.get(result, :score) || Map.get(result, :similarity)

    base = "[#{source}] #{text}"

    case score do
      value when is_float(value) -> "#{base} (score=#{Float.round(value, 4)})"
      _ -> base
    end
  end

  defp format_result(other), do: inspect(other, limit: :infinity)
end
