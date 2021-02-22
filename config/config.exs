# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pan,
  ecto_repos: [Pan.Repo]

# Configures the endpoint
config :pan, PanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1f0hthq3qJUXrZc8qckUy4/TW/BUKzycT2MiYn+wrMBXwcnWj9oAx9IYgfRmp930",
  render_errors: [view: PanWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Pan.PubSub,
  live_view: [signing_salt: "LMBJCcov"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
