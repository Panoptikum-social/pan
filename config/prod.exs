use Mix.Config

config :pan, Pan.Endpoint,
  https: [port: 8888,
          keyfile: "/etc/letsencrypt/live/beta.panoptikum.io/privkey.pem",
          certfile: "/etc/letsencrypt/live/beta.panoptikum.io/cert.pem"],
  url: [host: "beta.panoptikum.io", port: 80],
  cache_static_manifest: "priv/static/manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config[:version],
  force_ssl: [hsts: true]

config :logger, level: :info
config :phoenix, :serve_endpoints, true

import_config "prod.secret.exs"