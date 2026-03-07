import Config

config :arcana_context, ArcanaContext.Repo,
  database: System.get_env("ARCANA_DB_TEST_NAME", "ai_rules_context_test"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5
