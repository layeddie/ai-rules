defmodule ArcanaContext.MixProject do
  use Mix.Project

  def project do
    [
      app: :arcana_context,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {ArcanaContext.Application, []}
    ]
  end

  defp deps do
    [
      {:arcana, "~> 1.6"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:pgvector, "~> 0.3"}
    ]
  end
end
