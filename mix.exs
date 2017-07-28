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
     deps: deps()]
  end

  def application do
    [mod: {Pan, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger,
                    :gettext, :phoenix_ecto, :postgrex, :httpoison,
                    :comeonin, :sweet_xml, :timex, :earmark,
                    :font_awesome_phoenix, :quinn, :uuid, :html_sanitize_ex,
                    :scrivener_ecto, :scrivener_html, :bamboo, :bamboo_smtp,
                    :con_cache, :timelier, :tzdata, :tirexs, :floki]]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [{:phoenix, "~> 1.2.0"}, # web framework
     {:phoenix_pubsub, "~> 1.0"}, # PubSub messaging
     {:postgrex, ">= 0.0.0"}, # database adapter
     {:phoenix_ecto, "~> 3.0"}, # ORM (yes!)
     {:phoenix_html, "~> 2.4"}, # view layer
     {:phoenix_live_reload, "~> 1.0", only: :dev}, # live browser page reload on code changes
     {:gettext, "~> 0.9"}, # i18n and l10n
     {:cowboy, "~> 1.0.4"}, # web server
     {:comeonin, "~> 2.0"}, # password hashing library
     {:sweet_xml, "~> 0.6"}, # XML parser
     {:timex, "~> 3.1.24"}, # time conversion
     {:font_awesome_phoenix, "~> 1.0"}, # Font Awesome (just view helpers)
     {:httpoison, "~> 0.11.1"}, # http client
     {:hackney, "1.7.1"}, # erlang http client, had to increase version here
     {:exrm, "~> 1.0" }, # release manager
     {:quinn, "~> 1.0.2"}, # XML parser (another one)
     {:uuid, "~> 1.1"}, # UUID creation
#     {:html_sanitize_ex, "~> 1.0.0"}, # sanitizing html input (shownotes)
     {:html_sanitize_ex, git: "https://github.com/rrrene/html_sanitize_ex"}, # sanitizing html input (shownotes)
     {:scrivener_ecto, "~> 1.0"}, # pagination
     {:scrivener_html, "~> 1.1"}, # pagination view helper
     {:bamboo, "~> 0.8"}, # mailing
     {:bamboo_smtp, "~> 1.3"}, # mailing smtp adapter,
     {:con_cache, "~> 0.12.0"}, # key/value cache
     {:earmark, "~> 1.1.0"}, # Markdown parser
     {:timelier, "~> 0.9.2"}, # Cron like agent,
     {:tzdata, "~> 0.5.11"}, # mailing
     {:tirexs, "~> 0.8.5"}, # elasticsearch connector
     {:credo, github: "rrrene/credo", only: [:dev, :test]}, # Code analysis
     {:floki, "~> 0.17.0"}, # HTML parser
    ]
  end

  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
