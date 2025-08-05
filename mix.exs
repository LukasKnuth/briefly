defmodule MinimalistReader.MixProject do
  use Mix.Project

  def project do
    [
      app: :minimalist_reader,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MinimalistReader.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Web Framework
      {:phoenix, "~> 1.7.11"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.2"},
      {:gettext, "~> 0.20"},
      # LiveView
      {:phoenix_live_view, "~> 0.20.2"},
      {:lazy_html, "~> 0.1.3", only: :test},
      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      # Feed parsing
      {:saxy, "~> 1.6"},
      {:timex, "~> 3.7"},
      # Test coverage
      {:excoveralls, "~> 0.18.5", only: :test},
      # Web requests
      {:req, "~> 0.5.12"},
      # Config file format
      {:yaml_elixir, "~> 2.11"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind minimalist_reader", "esbuild minimalist_reader"],
      "assets.deploy": [
        "tailwind minimalist_reader --minify",
        "esbuild minimalist_reader --minify",
        "phx.digest"
      ]
    ]
  end
end
