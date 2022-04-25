defmodule Avalanche.MixProject do
  use Mix.Project

  @name "Avalanche"
  @source_url "https://github.com/HGInsights/avalanche"
  @version "0.2.0"

  def project do
    [
      app: :avalanche,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      source_url: @source_url,
      package: package(),
      docs: docs(),
      deps: deps(),
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Avalanche.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:finch, "~> 0.11.0"},
      {:jason, "~> 1.3"},
      {:joken, "~> 2.4"},
      {:nimble_options, "~> 0.4.0"},
      {:mentat, "~> 0.7.1"},
      {:plug, "~> 1.13"},
      {:req, github: "wojtekmach/req", ref: "115b65d"},
      {:telemetry, "~> 1.1", override: true},
      {:uuid, "~> 1.1"},
      {:bypass, "~> 2.1", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false, override: true},
      {:vapor, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :docs, runtime: false}
    ]
  end

  defp package() do
    [
      description: "Elixir Snowflake Connector built on top of the Snowflake SQL API v2.",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: @name,
      extras: ["CHANGELOG.md"],
      groups_for_extras: [
        CHANGELOG: "CHANGELOG.md"
      ]
    ]
  end

  defp preferred_cli_env,
    do: [
      "test.all": :test,
      qc: :test,
      credo: :test,
      dialyzer: :test,
      docs: :docs,
      "hex.publish": :docs
    ]

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix]
    ]
  end

  defp aliases do
    [
      credo: ["compile", "credo"],
      "test.all": ["test --include integration"],
      qc: ["format", "compile --warnings-as-errors", "credo --strict", "test"]
    ]
  end
end
