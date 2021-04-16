defmodule PanWeb.Live.Admin.Dashboard do
  alias PanWeb.Surface.Admin.Naming
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Link
  alias PanWeb.Surface.Admin.{Explorer, Col}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, schemas: Naming.schemas())}
  end

  def render(assigns) do
    ~H"""
    <Explorer id="admin_dashboard"
              title="Schemas"
              items={{ schema <- @schemas }}>
      <Col title="Schema">
        {{ Naming.model_in_plural(schema) }}
      </Col>
      <Col title="Data"
           class="text-center">
       <Link to={{Routes.databrowser_path(@socket, :index, Phoenix.Naming.resource_name(schema))}}
         label="Data"
         class="text-link hover:text-link-dark" />
      </Col>
      <Col title="Database Indices"
           class="text-center">
        <Link to={{Routes.databrowser_path(@socket, :db_indices, Phoenix.Naming.resource_name(schema))}}
              label="Database Indices"
              class="text-link hover:text-link-dark" />
      </Col>
    </Explorer>
    """
  end
end
