use Mix.Config

config :pan, Pan.Endpoint,
  https: [port: 8888,
          keyfile: "/etc/letsencrypt/live/alpha.panoptikum.io/privkey.pem",
          certfile: "/etc/letsencrypt/live/alpha.panoptikum.io/cert.pem"],
  url: [host: "panoptikum.io", port: 443],

  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version],
  force_ssl: [hsts: true],
  http: [compress: true]

config :logger, level: :info
config :phoenix, :serve_endpoints, true

config :timelier, crontab: [{{[42],:any,:any,:any,:any},
                            {Pan.Podcast,:import_stale_podcasts, []}}]

import_config "prod.secret.exs"