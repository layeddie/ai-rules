Postgrex.Types.define(
  ArcanaContext.PostgrexTypes,
  Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions()
)
