defmodule PanWeb.Live.Admin.Dashboard do
  use Surface.LiveView
  alias PanWeb.Surface.Tree

  def mount(_params, _session, socket) do
    {:ok, assign(socket, config: config())}
  end

  def config() do
    {:ok, application} = :application.get_application(PanWeb.Live.Admin.Dashboard)
    {:ok, config} = :application.get_all_key(application)

    {:ok, modules} = :application.get_key(application, :modules)
    _schemas = Enum.filter(modules, &({:__schema__, 1} in &1.__info__(:functions)))
    # PanWeb.Podcast.__schema__
    # PanWeb.Podcast.__changeset__
    # PanWeb.Podcast.__struct__
    config
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl">Admin Dashboard</h1>

    <div class="font-mono">📁 Root
      <Tree for={{ @config }} />
    </div>
    """
  end
end
