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
                    :gettext, :phoenix_ecto, :postgrex, :httpoison, :mogrify,
                    :comeonin, :sweet_xml, :timex, :earmark, :exactor,
                    :quinn, :uuid, :html_sanitize_ex,
                    :scrivener_ecto, :scrivener_html, :bamboo, :bamboo_smtp,
                    :timelier, :tzdata, :tirexs, :floki, :erlware_commons,
                    :ja_serializer, :bcrypt_elixir, :elixir_make, :p1_utils, :iconv,
                    :exactor]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:phoenix, "~> 1.3.3"}, # web framework
     {:phoenix_pubsub, "~> 1.0"}, # PubSub messaging
     {:postgrex, "0.13.5"}, # database adapter
     {:phoenix_ecto, "3.3.0"}, # ORM (yes!)
     {:phoenix_html, "2.11.2"}, # view layer
     {:phoenix_live_reload, "1.1.5", only: :dev}, # live browser page reload on code changes
     {:gettext, "~> 0.9"}, # i18n and l10n
     {:cowboy, "1.1.2"}, # web server
     {:comeonin, "4.1.1"}, # password hashing library
     {:bcrypt_elixir, "1.0.7"}, # algorithm used for comeonin
     {:sweet_xml, "~> 0.6"}, # XML parser
     {:timex, "~> 3.3.0"}, # time conversion
     {:httpoison, "~> 1.2.0"}, # http client
     {:hackney, "1.12.1"}, # erlang http client, had to increase version here
     {:distillery, "~> 1.5", runtime: false}, # release manager, distillery is deprecated
     {:quinn, "~> 1.1.2"}, # XML parser (another one)
     {:uuid, "~> 1.1.8"}, # UUID creation
     {:html_sanitize_ex, "1.3.0"}, # sanitizing html input (shownotes)
     {:scrivener_ecto, "1.3.0"}, # pagination
     {:scrivener_html, "1.7.1"}, # pagination view helper
     {:bamboo_smtp, "~> 1.5.0-rc.4"}, # mailing smtp adapter,
     {:bamboo, "~> 1.0.0"}, # mailing
     {:earmark, "1.2.5"}, # Markdown parser
     {:timelier, "~> 0.9.2"}, # Cron like agent,
     {:tzdata, "~> 0.5.17"}, # Timezone information
     {:tirexs, "~> 0.8.15"}, # elasticsearch connector
     {:credo, "0.9.3", only: [:dev, :test]}, # Code analysis
     {:floki, "~> 0.20.2"}, # HTML parser
     {:erlware_commons, "~> 1.1.0"},
     {:ja_serializer, git: "https://github.com/vt-elixir/ja_serializer"}, #Jsonapi.org serializer
     {:excoveralls, "~> 0.9.1", only: :test}, # Code coverage tool
     {:p1_utils, "1.0.11", manager: :rebar}, # dependency for iconv
     {:iconv, "~> 1.0.7", manager: :rebar}, # Unicode converter
     {:mogrify, "~> 0.6.1"}, # Imagemagick wrapper
     {:exactor, "~> 2.2.4", warn_missing: false}
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
