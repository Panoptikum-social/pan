defmodule Pan.MixProject do
  use Mix.Project

  def project do
    [
      app: :pan,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      # security-focused static analysis tool
      {:sobelow, "~> 0.8", only: :dev},
      # web framework
      # TODO: take this back, once scrivener is removed
      {:phoenix, "~> 1.5.8", override: true},
      # PubSub messaging
      {:phoenix_pubsub, "~> 2.0"},
      # phoenix support for ecto
      {:phoenix_ecto, "~> 4.1"},
      # ecto sql adapter
      {:ecto_sql, "~> 3.4"},
      # database adapter
      {:postgrex, "~> 0.14"},
      # reactive view layer
      {:phoenix_live_view, "~> 0.15.0"},
      # HTML parser
      {:floki, ">= 0.27.0"},
      # classic view layer
      {:phoenix_html, "~> 2.11"},
      # live browser page reload on code changes
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # live metrics dashboard
      {:phoenix_live_dashboard, "~> 0.4"},
      # Component library
      {:surface, "~> 0.4"},
      # telemetry_metrics
      {:telemetry_metrics, "~> 0.4"},
      # telemetry poller
      {:telemetry_poller, "~> 0.4"},
      # i18n library
      {:gettext, "~> 0.11"},
      # Json generation
      {:jason, "~> 1.1"},
      # web server plug
      {:plug_cowboy, "~> 2.0"},
      # algorithm used for comeonin
      {:bcrypt_elixir, "~> 2.1"},
      # color calculations
      {:tint, "~> 1.1"},

      ### imported from old app from here on

      # XML parser
      {:sweet_xml, "~> 0.6"},
      # time conversion
      {:timex, "~> 3.4"},
      # http client
      {:httpoison, "~> 1.6"},
      # erlang http client, had to increase version here
      {:hackney, "~> 1.15"},
      # XML parser (another one)
      {:quinn, "~> 1.1"},
      # UUID creation
      {:uuid, "~> 1.1"},
      # sanitizing html input (shownotes)
      {:html_sanitize_ex, "~> 1.4"},
      # pagination
      {:scrivener_ecto, "~> 2.3"},
      # pagination view helper
      {:scrivener_html, "~> 1.7"},
      # mailing smtp adapter,
      {:bamboo_smtp, "~> 3.0"},
      # TODO: Upgrade bamboo (only possible, when bamboo_smtp new version is ready)
      # mailing
      {:bamboo, "~> 1.4"},
      # Markdown parser
      {:earmark, "~> 1.4"},
      # Cron like agent,
      {:timelier, "~> 0.9"},
      # Timezone information
      {:tzdata, "~> 1.0"},
      # We have to override manually, as manticoresearch would want to see 3.0
      {:poison, "~> 4.0.1", override: true},
      # Code analysis
      {:credo, "~> 1.5", only: [:dev, :test]},
      # reuseable Erlang components
      {:erlware_commons, "~> 1.3"},
      # Jsonapi.org serializer
      {:ja_serializer, "~> 0.15"},
      # dependency for iconv
      {:p1_utils, "~> 1.0.13"},
      # Unicode converter
      {:iconv, "~> 1.0.12"},
      # Imagemagick wrapper
      {:mogrify, "~> 0.7"},
      # Simplifies implementation of GenServer based processes
      {:exactor, "~> 2.2", warn_missing: false},
      # HTTP Client
      {:httpotion, "~> 3.1"},
      # QR Code generation
      {:eqrcode, "~> 0.1.7"},
      # Creating a pidfile
      {:pid_file, "~> 0.1.1"},
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
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
