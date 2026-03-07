defmodule ArcanaContext.Repo do
  use Ecto.Repo,
    otp_app: :arcana_context,
    adapter: Ecto.Adapters.Postgres,
    priv: "priv/arcana_context_repo"
end
