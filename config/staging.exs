use Mix.Config

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

config :timelier,
  crontab: [
    {{42, :any, :any, :any, :any}, {PanWeb.Podcast, :import_stale_podcasts, []}},
    {{[0, 10, 20, 30, 40, 50], :any, :any, :any, :any}, {PanWeb.Image, :cache_missing, []}},
    {{[8, 18, 28, 38, 48, 58], :any, :any, :any, :any}, {Pan.Search, :push_missing, []}} #,
#    {{0, 6, :any, :any, :any}, {PanWeb.User, :pro_expiration, []}}
  ]

config :pan, :environment, "staging"

import_config "staging.secret.exs"
