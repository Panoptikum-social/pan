use Mix.Config

config :pan, Pan.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "p+SVheqFHkj2Z89dxUo/PoRR696q9G+mY9IPIbpm1bBHL1BJOawyku/GKnhT6RAs",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Pan.PubSub,
           adapter: Phoenix.PubSub.PG2],
  http: [compress: true]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :generators,
  migration: true,
  binary_id: false

config :pan, ecto_repos: [Pan.Repo]

config :scrivener_html, routes_helper: Pan.Router.Helpers

config :pan, Pan.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: "localhost",
  port: 25,
  username: false,
  password: false,
  tls: :if_available,
  ssl: false,
  retries: 1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
