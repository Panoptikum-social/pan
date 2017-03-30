use Mix.Config

config :pan, Pan.Endpoint,
  http: [port: 8888, compress: true],
  url: [scheme: "https", host: "panoptikum.io", port: 443],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version]

config :logger,
  backends: [:console,
             {Logger.Backends.ExceptionNotification, :exeception_notification}]

config :logger, level: :info
config :phoenix, :serve_endpoints, true

config :timelier, crontab: [{{[42],:any,:any,:any,:any},
                            {Pan.Podcast,:import_stale_podcasts, []}}]
config :timelier, crontab: [{{[48],:any,:any,:any,:any},
                            {Pan.Search,:push, [1]}}]

config :pan, :environment, "prod"

import_config "prod.secret.exs"