import Config

config :pan,
  ecto_repos: [Pan.Repo]

config :pan, PanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1f0hthq3qJUXrZc8qckUy4/TW/BUKzycT2MiYn+wrMBXwcnWj9oAx9IYgfRmp930",
  render_errors: [view: PanWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: :pan_pubsub,
  live_view: [signing_salt: "LMBJCcov"],
  http: [compress: false]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason
config :phoenix, :format_encoders, "json-api": Jason

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

config :tailwind,
  version: "4.1.18",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=assets/css/app.css
      --output=priv/static/assets/app.css
    ),
    cd: Path.expand("..", __DIR__),
  ],
  version_check: false,
  path: Path.expand("../assets/node_modules/.bin/tailwindcss", __DIR__)

config :esbuild,
  version: "0.13.10",
  pan: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --external:/web-player/* --external:/subscribe-button/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :pid_file, file: "./pan.pid"

config :surface, :components, [
  {Surface.Components.Form.ErrorTag,
   default_translator: {MyAppWeb.ErrorHelpers, :translate_error}},
  {Surface.Components.Form.ErrorTag,
   default_class:
     "inline-block px-2 mt-2 text-grapefruit bg-grapefruit/20 border border-dotted border-grapefruit"}
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
