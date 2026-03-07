defmodule ArcanaContext.Docs do
  @moduledoc """
  Helper functions for indexing and searching ai-rules documentation in Arcana.
  """

  import Ecto.Query, only: [from: 2]

  alias Arcana.Document
  alias ArcanaContext.Repo

  @default_collection "ai_rules_docs"

  @default_globs [
    "README.md",
    "AGENTS.md",
    "PROJECT_INIT.md",
    "elixir_examples.md",
    "configs/project_requirements.md",
    "docs/**/*.md",
    "patterns/**/*.md",
    "skills/**/SKILL.md"
  ]

  @core_globs [
    "README.md",
    "docs/quickstart-agents.md",
    "docs/mixed-search-strategy.md",
    "patterns/PATTERN_INDEX.md",
    "elixir_examples.md"
  ]

  @phoenix_guides_glob ".rules-phoenix/guides/**/*.md"

  @type ingest_result :: %{ingested: non_neg_integer(), failed: [{String.t(), term()}]}

  def default_collection, do: @default_collection

  def ingest_ai_rules_docs(opts \\ []) do
    ensure_embedder_ready!()

    root = Keyword.get(opts, :root, detect_ai_rules_root!())
    collection = Keyword.get(opts, :collection, @default_collection)
    include_phoenix_guides? = Keyword.get(opts, :include_phoenix_guides, true)
    core_only? = Keyword.get(opts, :core_only, false)
    explicit_paths = Keyword.get(opts, :paths, [])

    files =
      build_paths(explicit_paths, root, core_only?, include_phoenix_guides?)
      |> Enum.filter(&File.regular?/1)
      |> Enum.uniq()
      |> Enum.sort()

    Enum.reduce(files, %{ingested: 0, failed: []}, fn file, acc ->
      source_id = Path.relative_to(file, root)

      case reindex_file(file, source_id, collection) do
        :ok ->
          %{acc | ingested: acc.ingested + 1}

        {:error, reason} ->
          %{acc | failed: [{source_id, reason} | acc.failed]}
      end
    end)
    |> Map.update!(:failed, &Enum.reverse/1)
  end

  def search(query, opts \\ []) when is_binary(query) do
    Arcana.search(
      query,
      repo: Repo,
      collection: Keyword.get(opts, :collection, @default_collection),
      limit: Keyword.get(opts, :limit, 8)
    )
  end

  def detect_ai_rules_root! do
    env_root = System.get_env("AI_RULES_ROOT")

    cond do
      is_binary(env_root) and env_root != "" ->
        Path.expand(env_root)

      true ->
        find_root(Path.expand(File.cwd!()))
    end
  end

  defp find_root("/"), do: raise("Could not find ai-rules root. Set AI_RULES_ROOT.")

  defp find_root(path) do
    if File.exists?(Path.join(path, "AGENTS.md")) do
      path
    else
      path
      |> Path.dirname()
      |> find_root()
    end
  end

  defp build_globs(true, true), do: @core_globs ++ [@phoenix_guides_glob]
  defp build_globs(true, false), do: @core_globs
  defp build_globs(false, true), do: @default_globs ++ [@phoenix_guides_glob]
  defp build_globs(false, false), do: @default_globs

  defp build_paths([], root, core_only?, include_phoenix_guides?) do
    build_globs(core_only?, include_phoenix_guides?)
    |> Enum.flat_map(&Path.wildcard(Path.join(root, &1)))
  end

  defp build_paths(paths, root, _core_only?, _include_phoenix_guides?) do
    paths
    |> Enum.flat_map(fn path ->
      expanded = Path.expand(path, root)

      cond do
        String.contains?(path, "*") ->
          Path.wildcard(expanded)

        File.dir?(expanded) ->
          Path.wildcard(Path.join(expanded, "**/*.{md,txt,livemd,ex,exs}"))

        true ->
          [expanded]
      end
    end)
  end

  defp reindex_file(file, source_id, collection) do
    delete_existing_source(source_id)

    Arcana.ingest_file(
      file,
      repo: Repo,
      collection: collection,
      source_id: source_id,
      metadata: %{"source_path" => source_id, "source_type" => "ai_rules_doc"}
    )
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp delete_existing_source(source_id) do
    from(d in Document, where: d.source_id == ^source_id, select: d.id)
    |> Repo.all()
    |> Enum.each(fn id -> Arcana.delete(id, repo: Repo) end)
  end

  defp ensure_embedder_ready! do
    case Application.get_env(:arcana, :embedder, :local) do
      :openai ->
        if missing_openai_key?() do
          raise "ARCANA_EMBEDDER=openai requires OPENAI_API_KEY."
        end

      _ ->
        :ok
    end
  end

  defp missing_openai_key? do
    case System.get_env("OPENAI_API_KEY") do
      nil -> true
      "" -> true
      _ -> false
    end
  end
end
