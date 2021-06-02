use Mix.Config

config :pan, PanWeb.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "p+SVheqFHkj2Z89dxUo/PoRR696q9G+mY9IPIbpm1bBHL1BJOawyku/GKnhT6RAs",
  render_errors: [accepts: ~w(html json)],
  pubsub_server: Pan.PubSub,
  http: [compress: false]

config :pan, ecto_repos: [Pan.Repo]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason
config :phoenix, :format_encoders, "json-api": Jason

config :scrivener_html, routes_helper: PanWeb.Router.Helpers

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :pid_file, file: "./pan.pid"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
