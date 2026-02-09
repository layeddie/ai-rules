defmodule AiRulesAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :ai_rules_agent,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: "AI agent surface for Elixir/Phoenix/Ash projects (HTTP + stdio, allowlist, tests, docs)",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.5", only: :dev},
      {:jason, "~> 1.4"},
      {:req, "~> 0.4"},
      {:ex_json_schema, "~> 0.10"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/layeddie/ai-rules"},
      maintainers: ["ai-rules team"],
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE .formatter.exs)
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "credo --strict",
        "test"
      ]
    ]
  end
end
