import Config

config :pan, PanWeb.Endpoint,
  http: [port: 8888, compress: false],
  url: [scheme: "https", host: "panoptikum.io", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  check_origin: ["https://panoptikum.io", "https://ansible.local"],
  version: Mix.Project.config()[:version]

config :logger,
  backends: [:console, {Logger.Backends.ExceptionNotification, :exeception_notification}]

config :logger, level: :info
config :phoenix, :serve_endpoints, true
config :pan, :environment, "staging"

config :pan, :children, [
  Pan.Repo,
  PanWeb.Telemetry,
  {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
  PanWeb.Endpoint
]

import_config "staging.secret.exs"
