defmodule PanWeb.Live.Admin.Dashboard do
  use Surface.LiveView

  def mount(_params, _session, socket) do
    IO.inspect __MODULE__
    {:ok, socket}
  end


  def config() do
    {:ok, application} = :application.get_application(PanWeb.Live.Admin.Dashboard)
    {:ok, _config} = :application.get_all_key(:application)
    {:ok, modules} = :application.get_key(application, :modules)
    _schemas = Enum.filter(modules, &({:__schema__, 1} in &1.__info__(:functions)))
    # PanWeb.Podcast.__schema__
    # PanWeb.Podcast.__changeset__
    # PanWeb.Podcast.__struct__
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl">Admin Dashboard</h1>

    <p class="mt-4">That's how it started. 😊</p>

    <p class="mt-16">.jit-test</p>
    """
  end
end
