defmodule PanWeb.Live.Admin.Dashboard do
  alias PanWeb.Surface.Admin.Naming
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Link

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def schemas() do
    {:ok, application} = :application.get_application(PanWeb.Live.Admin.Dashboard)
    {:ok, modules} = :application.get_key(application, :modules)
    schemas = Enum.filter(modules, &({:__schema__, 1} in &1.__info__(:functions)))
    schemas
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl">Admin Dashboard</h1>

    <ul class="mt-4">
      <li :for={{ schema <- schemas() }}>
        <Link to={{Routes.databrowser_path(@socket, :index, Phoenix.Naming.resource_name(schema))}}
              label={{ Naming.model_in_plural(schema) }}
              class="text-link hover:text-link-dark" />
      </li>
    </ul>
    """
  end
end

#TODO: More Introspection
  # {:ok, config} = :application.get_all_key(application)
  # PanWeb.Podcast.__schema__(:fields)
  # PanWeb.Podcast.__changeset__
  # PanWeb.Podcast.__struct__
