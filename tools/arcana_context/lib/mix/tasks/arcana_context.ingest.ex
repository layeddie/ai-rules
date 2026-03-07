defmodule Mix.Tasks.ArcanaContext.Ingest do
  use Mix.Task

  @shortdoc "Ingest ai-rules docs into Arcana"

  @switches [
    root: :string,
    collection: :string,
    include_phoenix_guides: :boolean,
    skip_phoenix_guides: :boolean,
    core_only: :boolean,
    full: :boolean,
    path: :keep
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    root = opts[:root] || ArcanaContext.Docs.detect_ai_rules_root!()

    include_phoenix_guides? =
      not Keyword.get(opts, :skip_phoenix_guides, false) and
        Keyword.get(opts, :include_phoenix_guides, true)

    core_only? =
      if Keyword.get(opts, :full, false) do
        false
      else
        Keyword.get(opts, :core_only, false)
      end

    result =
      ArcanaContext.Docs.ingest_ai_rules_docs(
        root: root,
        collection: opts[:collection] || ArcanaContext.Docs.default_collection(),
        include_phoenix_guides: include_phoenix_guides?,
        core_only: core_only?,
        paths: Keyword.get_values(opts, :path)
      )

    Mix.shell().info("Ingested #{result.ingested} files")

    if result.failed != [] do
      Enum.each(result.failed, fn {source, reason} ->
        Mix.shell().error("Failed: #{source} -> #{inspect(reason)}")
      end)

      Mix.raise("Ingest completed with #{length(result.failed)} failures")
    end
  end
end
