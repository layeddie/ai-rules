import Config

config :test_project, TestProjectWeb.Endpoint,
  pubsub_server_name: TestProject.PubSub,
  live_view: [signing_salt: "Jl/1W7FJv8M2sF7S+J7Jd8l8Q7R5l3gK3cX8q7F4m3g="]

config :test_project, :ecto,
  repo: TestProject.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10,
  ssl: true,
  database_url: System.get_env("DATABASE_URL", "postgres://localhost/test_project_dev"),
  stacktrace: true,
  log: true

# Configure Codicil
if Code.ensure_loaded?(Codicil) do
  config :codicil,
    llm_provider: System.get_env("CODICIL_LLM_PROVIDER", "openai"),
    openai_api_key: System.get_env("OPENAI_API_KEY"),
    anthropic_api_key: System.get_env("ANTHROPIC_API_KEY"),
    database: System.get_env("CODICIL_DATABASE", "local_sqlite")
end

# Configure Jido AI
config :jido_ai,
  providers: %{
    anthropic: [
      api_key: System.get_env("ANTHROPIC_API_KEY"),
      models: [
        claude_3_5_sonnet: "claude-3-5-sonnet-20241022",
        claude_3_opus: "claude-3-opus-20240219"
      ]
    ],
    openai: [
      api_key: System.get_env("OPENAI_API_KEY"),
      models: [
        gpt_4o: "gpt-4o",
        gpt_4_turbo: "gpt-4-turbo"
      ]
    ],
    local: [
      base_url: System.get_env("LOCAL_LLM_URL", "http://localhost:11434"),
      models: [
        llama3: "llama3"
      ]
    ]
  },
  default_provider: System.get_env("JIDO_DEFAULT_PROVIDER", "anthropic")

# Configure Swarm Ex
config :swarm_ex,
  telemetry_enabled: true,
  telemetry_prefix: "test_project.swarm_ex"

# Configure Anubis MCP
if Code.ensure_loaded?(Anubis.Server) do
  config :anubis_mcp,
    transport: :streamable_http,
    server_name: "test_project_mcp"
end

config :test_project, :logger, level: :info

import_config "#{config_env()}.exs"
