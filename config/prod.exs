use Mix.Config

config :pan, Pan.Endpoint,
  http: [port: 8888, compress: true],
  url: [schema: "https", host: "panoptikum.io", port: 443],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version]


config :logger, level: :info
config :phoenix, :serve_endpoints, true

config :timelier, crontab: [{{[42],:any,:any,:any,:any},
                            {Pan.Podcast,:import_stale_podcasts, []}}]

import_config "prod.secret.exs"