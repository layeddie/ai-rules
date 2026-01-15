defmodule AiRulesContext.MixProject do
  use Mix.Project

  @version "1.2.0"

  def project do
    [
      app: :ai_rules_context,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :iex],
      mod: {AiRulesContext.Application, []}
    ]
  end

  defp deps do
    [
      {:arcana, "~> 1.2"},
      {:pgvector, "~> 0.3"},
      {:postgrex, "~> 0.19"},
      {:ecto_sql, "~> 3.12"},
      {:bumblebee, "~> 0.6"},
      {:nx, "~> 0.9"},
      {:emlx, "~> 0.1"},
      {:jason, "~> 1.4"}
    ]
  end
end
