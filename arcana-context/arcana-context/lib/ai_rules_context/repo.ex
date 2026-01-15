defmodule AiRulesContext.Repo do
  use Ecto.Repo,
    otp_app: :ai_rules_context,
    adapter: Ecto.Adapters.Postgres,
    url: System.get_env("DATABASE_URL") || "postgresql://postgres@localhost:5432/ai_rules_context_dev",
    database: "ai_rules_context_dev",
    pool_size: 10
end
