defmodule PanWeb.Live.Admin.Dashboard do
  alias PanWeb.Surface.Admin.Naming
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Link

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl">Admin Dashboard</h1>

    <ul class="mt-4">
      <li :for={{ schema <- Naming.schemas() }}>
        <Link to={{Routes.databrowser_path(@socket, :index, Phoenix.Naming.resource_name(schema))}}
              label={{ Naming.model_in_plural(schema) }}
              class="text-link hover:text-link-dark" />
      </li>
    </ul>
    """
  end
end
