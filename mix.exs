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
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [
       "coveralls": :test,
       "coveralls.detail": :test,
       "coveralls.post": :test,
       "coveralls.html": :test
     ]
    ]
  end

  def application do
    [mod: {Pan, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger,
                    :gettext, :phoenix_ecto, :postgrex, :httpoison,
                    :comeonin, :sweet_xml, :timex, :earmark,
                    :font_awesome_phoenix, :quinn, :uuid, :html_sanitize_ex,
                    :scrivener_ecto, :scrivener_html, :bamboo, :bamboo_smtp,
                    :con_cache, :timelier, :tzdata, :tirexs, :floki, :erlware_commons,
                    :ja_serializer,  :bcrypt_elixir, :elixir_make, :p1_utils, :iconv]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.3.0"}, # web framework
     {:phoenix_pubsub, "~> 1.0"}, # PubSub messaging
     {:postgrex, "0.13.3"}, # database adapter
     {:phoenix_ecto, "3.3.0"}, # ORM (yes!)
     {:phoenix_html, "2.10.5"}, # view layer
     {:phoenix_live_reload, "1.1.3", only: :dev}, # live browser page reload on code changes
     {:gettext, "~> 0.9"}, # i18n and l10n
     {:cowboy, "1.1.2"}, # web server
     {:comeonin, "4.0.3"}, # password hashing library
     {:bcrypt_elixir, "1.0.4"}, # algorithm used for comeonin
     {:sweet_xml, "~> 0.6"}, # XML parser
     {:timex, "~> 3.1.24"}, # time conversion
     {:font_awesome_phoenix, "~> 1.0"}, # Font Awesome (just view helpers)
     {:httpoison, "~> 0.13.0"}, # http client
     {:hackney, "1.10.1"}, # erlang http client, had to increase version here
     {:distillery, "~> 1.5", runtime: false}, # release manager, distillery is deprecated
     {:quinn, "~> 1.0.2"}, # XML parser (another one)
     {:uuid, "~> 1.1.8"}, # UUID creation
     {:html_sanitize_ex, "1.3.0"}, # sanitizing html input (shownotes)
     {:scrivener_ecto, "1.3.0"}, # pagination
     {:scrivener_html, "1.7.1"}, # pagination view helper
     {:bamboo, "~> 0.8"}, # mailing
     {:bamboo_smtp, "~> 1.4"}, # mailing smtp adapter,
     {:con_cache, "~> 0.12.1"}, # key/value cache
     {:earmark, "1.2.3"}, # Markdown parser
     {:timelier, "~> 0.9.2"}, # Cron like agent,
     {:tzdata, "~> 0.5.13"}, # Timezone information
     {:tirexs, "~> 0.8.15"}, # elasticsearch connector
     {:credo, "0.8.10", only: [:dev, :test]}, # Code analysis
     {:floki, "~> 0.19.0"}, # HTML parser
     {:relx, "3.24.1"}, # Release assembler (asset compilation failed with 3.22.0)
     {:erlware_commons, "~> 1.0"},
     {:ja_serializer, git: "https://github.com/vt-elixir/ja_serializer"}, #Jsonapi.org serializer
     {:excoveralls, "~> 0.7", only: :test}, # Code coverage tool
     {:p1_utils, "1.0.10", manager: :rebar}, # dependency for iconv
     {:iconv, "~> 1.0.0", manager: :rebar} # Unicode converter
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
