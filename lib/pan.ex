defmodule Pan do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Phoenix.PubSub, [name: Pan.PubSub, adapter: Phoenix.PubSub.PG2]},
      supervisor(PanWeb.Endpoint, []),
      supervisor(Pan.Repo, []),
      worker(PidFile.Worker, [[file: "pan.pid"]])
    ]

    opts = [strategy: :one_for_one, name: Pan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
