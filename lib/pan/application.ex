defmodule Pan.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Pan.Repo,
      PanWeb.Telemetry,
      {Phoenix.PubSub, name: :pan_pubsub, adapter: Phoenix.PubSub.PG2},
      PanWeb.Endpoint,
      {PidFile.Worker, file: "pan.pid"},
      Pan.Job.ImportStalePodcasts
    ]

    opts = [strategy: :one_for_one, name: Pan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
