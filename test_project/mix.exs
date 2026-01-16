defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: Mix.Project.elixirc_paths(Mix.env()),
      compilers: Mix.Project.compilers(),
      build_embedded: "lib/test_project_web",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: ["sh"]
    ]
  end

  def application do
    [
      mod: {TestProject.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Core Phoenix dependencies
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.17"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7"},

      # Elixir-native tools
      {:anubis_mcp, "~> 0.17.0"},
      {:jido_ai, "~> 0.5.3"},
      {:swarm_ex, "~> 0.2.0"},
      {:codicil, "~> 0.7", only: [:dev, :test]},

      # Additional dependencies
      {:comeonin, "~> 0.18"}
    ]
  end
end
