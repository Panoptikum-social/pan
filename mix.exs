defmodule Pan.Mixfile do
  use Mix.Project

  def project do
    [app: :pan,
     version: "0.0.1",
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
                    :exactor]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.4.0", override: true}, # web framework
     {:phoenix_pubsub, "~> 1.1.1"}, # PubSub messaging
     {:postgrex, "0.14.0"}, # database adapter
     {:ecto_sql, "~> 3.0"}, # ecto sql adapter
     {:phoenix_ecto, "~> 4.0.0"}, # phoenix support for ecto
     {:phoenix_html, "2.12.0"}, # view layer
     {:phoenix_live_reload, "1.2.0", only: :dev}, # live browser page reload on code changes
     {:gettext, "~> 0.9"}, # i18n and l10n
     {:plug_cowboy, "~> 2.0"}, # web server
     {:plug, "~> 1.7.1"}, # connection adapters
     {:comeonin, "4.1.1"}, # password hashing library
     {:bcrypt_elixir, "1.1.1"}, # algorithm used for comeonin
     {:sweet_xml, "~> 0.6"}, # XML parser
     {:timex, "~> 3.4.2"}, # time conversion
     {:httpoison, "~> 1.4.0"}, # http client
     {:hackney, "1.14.3"}, # erlang http client, had to increase version here
     {:distillery, "~> 2.0.12", runtime: false}, # release manager
     {:quinn, "~> 1.1.2"}, # XML parser (another one)
     {:uuid, "~> 1.1.8"}, # UUID creation
     {:html_sanitize_ex, "1.3.0"}, # sanitizing html input (shownotes)
     {:scrivener_ecto, "2.0.0"}, # pagination
     {:scrivener_html, "~> 1.7.1"}, # pagination view helper
     {:bamboo_smtp, "~> 1.6.0"}, # mailing smtp adapter,
     {:bamboo, "~> 1.1.0"}, # mailing
     {:earmark, "1.2.6"}, # Markdown parser
     {:timelier, "~> 0.9.2"}, # Cron like agent,
     {:tzdata, "~> 0.5.19"}, # Timezone information
     {:tirexs, "~> 0.8.15"}, # elasticsearch connector
     {:credo, "0.10.2", only: [:dev, :test]}, # Code analysis
     {:floki, "~> 0.20.4"}, # HTML parser
     {:erlware_commons, "~> 1.3.0"},
     {:ja_serializer, git: "https://github.com/vt-elixir/ja_serializer"}, #Jsonapi.org serializer
     {:p1_utils, "1.0.13", manager: :rebar}, # dependency for iconv
     {:iconv, "~> 1.0.10", manager: :rebar}, # Unicode converter
     {:mogrify, "~> 0.6.1"}, # Imagemagick wrapper
     {:exactor, "~> 2.2.4", warn_missing: false}, # Simplifies implementation of GenServer based processes
     {:jason, "~> 1.0"}, # Json generation
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
