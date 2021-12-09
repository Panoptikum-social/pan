import Config

config :pan,
  ecto_repos: [Pan.Repo]

config :pan, PanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1f0hthq3qJUXrZc8qckUy4/TW/BUKzycT2MiYn+wrMBXwcnWj9oAx9IYgfRmp930",
  render_errors: [view: PanWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Pan.PubSub,
  live_view: [signing_salt: "LMBJCcov"],
  http: [compress: false]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :scrivener_html, routes_helper: PanWeb.Router.Helpers

config :phoenix, :json_library, Jason
config :phoenix, :format_encoders, "json-api": Jason

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :esbuild,
  version: "0.13.10",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :pid_file, file: "./pan.pid"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
