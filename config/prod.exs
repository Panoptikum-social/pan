use Mix.Config

config :pan, PanWeb.Endpoint,
  http: [port: 8888, compress: true],
  url: [scheme: "https", host: "panoptikum.io", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version]

config :logger, backends:
  [:console, {Logger.Backends.ExceptionNotification, :exeception_notification}]

config :logger, level: :info
config :phoenix, :serve_endpoints, true

config :timelier, crontab: [
  {{42, :any, :any, :any, :any}, {PanWeb.Podcast, :import_stale_podcasts, []}},
  {{48, :any, :any, :any, :any}, {Pan.Search,     :push, [2]}},
  {{0,     6, :any, :any, :any}, {PanWeb.User,    :pro_expiration, []}},
]

config :pan, :environment, "prod"

import_config "prod.secret.exs"

config :pan, Pan.Repo, ownership_timeout: 300000