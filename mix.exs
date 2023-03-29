defmodule Avalanche.MixProject do
  use Mix.Project

  @name "Avalanche"
  @source_url "https://github.com/HGInsights/avalanche"

  @version_file Path.join(__DIR__, ".version")
  @external_resource @version_file
  @version (case Regex.run(~r/^([\d\.\w-]+)/, File.read!(@version_file), capture: :all_but_first) do
              [version] -> version
              nil -> "0.0.0"
            end)

  def project do
    [
      app: :avalanche,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: preferred_cli_env()
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
      {:jason, "~> 1.3"},
      {:joken, "~> 2.6"},
      {:nimble_options, "~> 0.4 or ~> 1.0"},
      {:cachex, "~> 3.6"},
      {:plug, "~> 1.13"},
      {:req, "~> 0.3.6"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:bypass, "~> 2.1", only: [:dev, :test]},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :docs], runtime: false},
      {:eflambe, "~> 0.3", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: [:docs], runtime: false},
      {:excoveralls, "~> 0.16", only: [:dev, :test]},
      {:mimic, "~> 1.7", only: [:dev, :test]},
      {:mox, "~> 1.0", only: :test},
      {:mix_test_watch, "~> 1.1", only: [:test, :dev]},
      {:vapor, "~> 0.10", only: [:dev, :test, :docs], runtime: false},
      {:decimal, "~> 2.0"}
    ]
  end

  defp package() do
    [
      description: "Elixir Snowflake Connector built on top of the Snowflake SQL API v2.",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* .version),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "CHANGELOG" => "https://github.com/HGInsights/avalanche/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: @name
    ]
  end

  defp preferred_cli_env,
    do: [
      bless: :test,
      qc: :test,
      coveralls: :test,
      "coveralls.html": :test,
      credo: :test,
      docs: :docs,
      dialyzer: :dev,
      "test.all": :test
    ]

  defp aliases do
    [
      "test.all": ["test --include integration"],
      bless: "qc",
      qc: [
        "format",
        "compile --warnings-as-errors",
        "credo --strict",
        "deps.unlock --check-unused",
        "coveralls.html --exclude skip_ci"
      ]
    ]
  end
end
