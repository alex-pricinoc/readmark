defmodule Readmark.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :readmark,
      version: @version,
      elixir: "~> 1.14",
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
      mod: {Readmark.Application, []},
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
      {:phoenix, "~> 1.7.1"},
      {:phoenix_live_view, "~> 0.18.18"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_ecto, "~> 4.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:file_system, "~> 0.2.10", only: :dev},
      {:ecto_sql, "~> 3.6"},
      {:floki, ">= 0.30.0"},
      {:bcrypt_elixir, "~> 3.0"},
      {:esbuild, "~> 0.5", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1.8", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:excoveralls, "~> 0.10", only: :test},
      {:gen_smtp, "~> 1.2"},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:quarto, "~> 1.1"},
      {:oban, "~> 2.13"},
      {:timex, "~> 3.7"},
      {:kday, "~> 1.0"},
      {:mox, "~> 1.0", only: :test},
      {:image, "~> 0.26.0"},
      {:rustler, "~> 0.27.0"}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      localize: ["gettext.extract", "gettext.merge priv/gettext"]
    ]
  end
end
