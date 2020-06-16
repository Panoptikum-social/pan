defmodule Pan.Mixfile do
  use Mix.Project

  def project do
    [app: :pan,
     version: "0.0.2",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
    ]
  end

  def application do
    [mod: {Pan, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger,
                    :gettext, :phoenix_ecto, :postgrex, :httpoison, :mogrify,
                    :comeonin, :sweet_xml, :timex, :earmark, :exactor, :ecto_sql,
                    :quinn, :uuid, :html_sanitize_ex, :parse_trans,
                    :scrivener_ecto, :scrivener_html, :bamboo, :bamboo_smtp,
                    :timelier, :tzdata, :tirexs, :floki, :erlware_commons,
                    :ja_serializer, :bcrypt_elixir, :elixir_make, :p1_utils, :iconv,
                    :exactor, :jason, :plug_cowboy, :httpotion]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.5.1", override: true}, # web framework
     {:phoenix_pubsub, "~> 2.0"}, # PubSub messaging
     {:postgrex, "~> 0.14"}, # database adapter
     {:ecto_sql, "~> 3.3"}, # ecto sql adapter
     {:phoenix_ecto, "~> 4.0"}, # phoenix support for ecto
     {:phoenix_html, "~> 2.1"}, # view layer
     {:phoenix_live_reload, "~> 1.2", only: :dev}, # live browser page reload on code changes
     {:gettext, "~> 0.17"}, # i18n and l10n
     {:plug_cowboy, "~> 2.0"}, # web server plug
     {:plug, "~> 1.8"}, # connection adapters
     {:bcrypt_elixir, "~> 2.1"}, # algorithm used for comeonin
     {:sweet_xml, "~> 0.6"}, # XML parser
     {:timex, "~> 3.4"}, # time conversion
     {:httpoison, "~> 1.6"}, # http client
     {:hackney, "~> 1.15"}, # erlang http client, had to increase version here
     {:distillery, "~> 2.0", runtime: false}, # release manager
     {:quinn, "~> 1.1"}, # XML parser (another one)
     {:uuid, "~> 1.1"}, # UUID creation
     {:html_sanitize_ex, "~> 1.4"}, # sanitizing html input (shownotes)
     {:scrivener_ecto, "~> 2.3"}, # pagination
     {:scrivener_html, "~> 1.7"}, # pagination view helper
     {:bamboo_smtp, "~> 2.1"}, # mailing smtp adapter,
     {:bamboo, "~> 1.4"}, # mailing
     {:earmark, "~> 1.4"}, # Markdown parser
     {:timelier, "~> 0.9"}, # Cron like agent,
     {:tzdata, "~> 1.0"}, # Timezone information
     {:tirexs, "~> 0.8"}, # elasticsearch connector
     {:credo, "~> 1.2", only: [:dev, :test]}, # Code analysis
     {:floki, "~> 0.25"}, # HTML parser
     {:erlware_commons, "~> 1.3"}, #reuseable Erlang components
     {:ja_serializer, "~> 0.15"}, #Jsonapi.org serializer
     {:p1_utils, "~> 1.0.13"}, # dependency for iconv
     {:iconv, "~> 1.0.10", git: "https://github.com/processone/iconv"}, # Unicode converter
     {:mogrify, "~> 0.7"}, # Imagemagick wrapper
     {:exactor, "~> 2.2", warn_missing: false}, # Simplifies implementation of GenServer based processes
     {:jason, "~> 1.1"}, # Json generation,
     {:httpotion, "~> 3.1"}
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
