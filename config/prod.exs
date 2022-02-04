import Config

config :pan, PanWeb.Endpoint,
  http: [port: 8888, compress: false],
  url: [scheme: "https", host: "panoptikum.io", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  check_origin: ["https://panoptikum.io", "https://ansible.local"],
  version: Mix.Project.config()[:version]

# Do not print debug messages in production
config :logger, level: :info

config :logger,
  backends: [:console, {Logger.Backends.ExceptionNotification, :exception_notification}]

config :phoenix, :serve_endpoints, true

config :pan, :environment, "prod"

config :pan, :children, [
  Pan.Repo,
  PanWeb.Telemetry,
  {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
  PanWeb.Endpoint,
  {PidFile.Worker, file: "pan.pid"},
  Pan.Job.ImportStalePodcasts,
  Pan.Job.CacheMissingImages,
  Pan.Job.PushMissingSearchIndex,
  Pan.Job.UserProExpiration
]

import_config "prod.secret.exs"
