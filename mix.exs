defmodule Pan.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pan,
      version: "0.0.2",
      elixir: "~> 1.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Pan, []},
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :cowboy,
        :logger,
        :gettext,
        :phoenix_ecto,
        :postgrex,
        :httpoison,
        :mogrify,
        :comeonin,
        :sweet_xml,
        :timex,
        :earmark,
        :exactor,
        :ecto_sql,
        :quinn,
        :uuid,
        :html_sanitize_ex,
        :parse_trans,
        :scrivener_ecto,
        :scrivener_html,
        :bamboo,
        :bamboo_smtp,
        :timelier,
        :tzdata,
        :tirexs,
        :floki,
        :erlware_commons,
        :ja_serializer,
        :bcrypt_elixir,
        :elixir_make,
        :p1_utils,
        :iconv,
        :exactor,
        :jason,
        :plug_cowboy,
        :httpotion
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    # web framework
    [
      {:phoenix, "~> 1.5.4", override: true},
      # PubSub messaging
      {:phoenix_pubsub, "~> 2.0"},
      # database adapter
      {:postgrex, "~> 0.14"},
      # ecto sql adapter
      {:ecto_sql, "~> 3.3"},
      # phoenix support for ecto
      {:phoenix_ecto, "~> 4.0"},
      # view layer
      {:phoenix_html, "~> 2.1"},
      # live browser page reload on code changes
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # i18n and l10n
      {:gettext, "~> 0.17"},
      # web server plug
      {:plug_cowboy, "~> 2.0"},
      # connection adapters
      {:plug, "~> 1.8"},
      # algorithm used for comeonin
      {:bcrypt_elixir, "~> 2.1"},
      # XML parser
      {:sweet_xml, "~> 0.6"},
      # time conversion
      {:timex, "~> 3.4"},
      # http client
      {:httpoison, "~> 1.6"},
      # erlang http client, had to increase version here
      {:hackney, "~> 1.15"},
      # release manager
      {:distillery, "~> 2.0", runtime: false},
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
      # mailing
      {:bamboo, "~> 1.4"},
      # Markdown parser
      {:earmark, "~> 1.4"},
      # Cron like agent,
      {:timelier, "~> 0.9"},
      # Timezone information
      {:tzdata, "~> 1.0"},
      # elasticsearch connector
      {:tirexs, "~> 0.8"},
      # Code analysis
      {:credo, "~> 1.2", only: [:dev, :test]},
      # HTML parser
      {:floki, "~> 0.25"},
      # reuseable Erlang components
      {:erlware_commons, "~> 1.3"},
      # Jsonapi.org serializer
      {:ja_serializer, "~> 0.15"},
      # dependency for iconv
      {:p1_utils, "~> 1.0.13"},
      # Unicode converter
      {:iconv, "~> 1.0.10", git: "https://github.com/processone/iconv"},
      # Imagemagick wrapper
      {:mogrify, "~> 0.7"},
      # Simplifies implementation of GenServer based processes
      {:exactor, "~> 2.2", warn_missing: false},
      # Json generation,
      {:jason, "~> 1.1"},
      {:httpotion, "~> 3.1"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
