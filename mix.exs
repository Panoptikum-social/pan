defmodule Pan.MixProject do
  use Mix.Project

  def project do
    [
      app: :pan,
      version: "1.0.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Pan.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
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
      # web framework
      {:phoenix, "~> 1.6.6"},
      # phoenix support for ecto
      {:phoenix_ecto, "~> 4.4.0"},
      # ecto sql adapter
      {:ecto_sql, "~> 3.10.1"},
      # database adapter
      {:postgrex, "~> 0.17.1"},
      # reactive view layer
      {:phoenix_live_view, "0.18.16", override: true},
      # HTML parser
      {:floki, "~> 0.34.2"},
      # classic view layer
      {:phoenix_html, "~> 3.0"},
      # live metrics dashboard
      {:phoenix_live_dashboard, "~> 0.7.2"},
      # phoenix classic views
      {:phoenix_view, "~> 2.0.2"},
      # Providing postgres stats for liveview
      {:ecto_psql_extras, "~> 0.6"},
      # Component library
      {:surface, "~> 0.9.4"},
      # telemetry_metrics
      {:telemetry_metrics, "~> 0.6"},
      # telemetry poller
      {:telemetry_poller, "~> 1.0"},
      # i18n library
      {:gettext, "~> 0.11"},
      # web server plug
      {:plug_cowboy, "~> 2.0"},
      # algorithm used for comeonin
      {:bcrypt_elixir, "~> 3.0"},
      # time conversion
      {:timex, "~> 3.7"},
      # http client
      {:httpoison, "~> 2.1.0"},
      # XML parser
      {:quinn, "~> 1.1"},
      # UUID creation
      {:uuid, "~> 1.1"},
      # sanitizing html input (shownotes)
      {:html_sanitize_ex, "~> 1.4"},
      # mailing smtp adapter,
      {:bamboo_smtp, "~> 4.2.2"},
      # bamboo phoenix integration
      {:bamboo_phoenix, "~> 1.0"},
      # Markdown parser
      {:earmark, "~> 1.4"},
      # Timezone information
      {:tzdata, "~> 1.0"},
      # Jsonapi.org serializer
      {:ja_serializer, "~> 0.15"},
      # Unicode converter
      {:iconv, "~> 1.0.12"},
      # Imagemagick wrapper
      {:mogrify, "~> 0.7"},
      # QR Code generation
      {:eqrcode, "~> 0.1.7"},
      # Creating a pidfile
      {:pid_file, "~> 0.2"},

      # Mix task invoking esbuild
      {:esbuild, "~> 0.7.0", runtime: Mix.env() == :dev},
      # live browser page reload on code changes
      {:phoenix_live_reload, "~> 1.3.3", only: :dev},
      # Code analysis
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:heex_formatter, github: "feliperenan/heex_formatter", only: :dev}
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
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "cmd --cd assets npm run deploy",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
