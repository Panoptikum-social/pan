defmodule Pan.MixProject do
  use Mix.Project

  def project do
    [
      app: :pan,
      version: "1.0.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers() ++ [:surface],
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
      {:phoenix, "~> 1.7.12"},
      # phoenix support for ecto
      {:phoenix_ecto, "~> 4.6.3"},
      # ecto sql adapter
      {:ecto_sql, "~> 3.12.1"},
      # database adapter
      {:postgrex, "~> 0.19.2"},
      # reactive view layer
      {:phoenix_live_view, "~> 0.20.14"},
      # HTML parser
      {:floki, "~> 0.36.1"},
      # classic view layer
      {:phoenix_html, "~> 3.3.3"},
      # live metrics dashboard
      {:phoenix_live_dashboard, "~> 0.8.0"},
      # phoenix classic views
      {:phoenix_view, "~> 2.0.2"},
      # Providing postgres stats for liveview
      {:ecto_psql_extras, "~> 0.6"},
      # Component library
      {:surface, "~> 0.11.4"},
      # telemetry_metrics
      {:telemetry_metrics, "~> 1.0.0"},
      # telemetry poller
      {:telemetry_poller, "~> 1.1.0"},
      # i18n library
      {:gettext, "~> 0.11"},
      # web server plug
      {:plug_cowboy, "~> 2.0"},
      # algorithm used for comeonin
      {:bcrypt_elixir, "~> 3.0"},
      # time conversion
      {:timex, "~> 3.7"},
      # http client
      {:httpoison, "~> 2.2.1"},
      # XML parser
      {:quinn, "~> 1.1"},
      # UUID creation
      {:uuid, "~> 1.1"},
      # sanitizing html input (shownotes)
      {:html_sanitize_ex, "~> 1.4"},
      # mailing
      {:swoosh, "~> 1.17.2"},
      {:gen_smtp, "~> 1.2.0"},
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
      {:esbuild, "~> 0.8.1", runtime: Mix.env() == :dev},
      # live browser page reload on code changes
      {:phoenix_live_reload, "~> 1.5.3", only: :dev},
      # Code analysis
      {:credo, "~> 1.5", only: [:dev, :test]}
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
