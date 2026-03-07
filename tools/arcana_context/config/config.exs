import Config

pool_size =
  case Integer.parse(System.get_env("ARCANA_DB_POOL_SIZE", "10")) do
    {value, ""} when value > 0 -> value
    _ -> 10
  end

embedder =
  case String.downcase(System.get_env("ARCANA_EMBEDDER", "local")) do
    "local" -> :local
    _ -> :openai
  end

config :arcana_context,
  ecto_repos: [ArcanaContext.Repo]

config :arcana_context, ArcanaContext.Repo,
  username: System.get_env("ARCANA_DB_USER", System.get_env("USER", "postgres")),
  password: System.get_env("ARCANA_DB_PASSWORD", ""),
  hostname: System.get_env("ARCANA_DB_HOST", "localhost"),
  port: String.to_integer(System.get_env("ARCANA_DB_PORT", "5432")),
  database: System.get_env("ARCANA_DB_NAME", "ai_rules_context"),
  pool_size: pool_size,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  types: ArcanaContext.PostgrexTypes,
  priv: "priv/arcana_context_repo"

config :arcana,
  vector_store: :pgvector,
  embedder: embedder

config :arcana, :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  model: System.get_env("ARCANA_OPENAI_EMBED_MODEL", "text-embedding-3-small")

import_config "#{config_env()}.exs"
