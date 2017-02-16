defmodule Pan do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Pan.Endpoint, []),
      supervisor(Pan.Repo, []),
      supervisor(ConCache, [[ttl_check: :timer.seconds(10),
                             ttl: :timer.seconds(600)],
                            [name: :slow_cache]],[id: :slow_cache]),
      supervisor(ConCache, [[ttl_check: :timer.seconds(10),
                             ttl: :timer.seconds(600)],
                            [name: :fast_cache]],[id: :fast_cache]),
    ]

    opts = [strategy: :one_for_one, name: Pan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Pan.Endpoint.config_change(changed, removed)
    :ok
  end
end
