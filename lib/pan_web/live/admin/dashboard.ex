defmodule PanWeb.Live.Admin.Dashboard do
  alias PanWeb.Surface.Admin.Naming
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias Surface.Components.Link
  alias PanWeb.Surface.Admin.{Explorer, Col, Tools}

  def mount(_params, _session, socket) do
    schemas =
      Naming.schemas()
      |> Enum.map(&%{title: &1})
    {:ok, assign(socket, id: "admin_dashboard", schemas: schemas)}
  end

  def handle_info({:items, schemas}, socket) do
    {:noreply, assign(socket, schemas: schemas)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    schemas =
      socket.assigns.schemas
      |> Enum.map(&Tools.toggle_select_single(&1, String.to_integer(id)))

    {:noreply, assign(socket, schemas: schemas)}
  end

  def render(assigns) do
    ~H"""
    <Explorer id="schemas"
              title="Schemas"
              items={{ schema <- @schemas }}>
      <Col title="Schema">
        {{ schema.title |> Naming.model_in_plural }}
      </Col>
      <Col title="Data"
            class="text-center">
        <Link to={{ Routes.databrowser_path(@socket, :index, Phoenix.Naming.resource_name(schema.title)) }}
          label="Data"
          class="text-link hover:text-link-dark" />
      </Col>
      <Col title="Database Indices"
            class="text-center">
        <Link to={{ Routes.databrowser_path(@socket, :db_indices, Phoenix.Naming.resource_name(schema.title)) }}
              label="Database Indices"
              class="text-link hover:text-link-dark" />
      </Col>
    </Explorer>
    """
  end
end
