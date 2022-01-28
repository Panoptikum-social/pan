defmodule PanWeb.Live.Admin.Dashboard do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Surface.Admin.{Explorer, Col, Tools, ToolbarItem, Naming}
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    schemas =
      Naming.schemas
      |> Enum.map(&%{title: &1})
    {:ok, assign(socket, id: "admin_dashboard",
                         schemas: schemas,
                         selected_count: 0)}
  end

  def handle_info({:items, schemas}, socket) do
    {:noreply, assign(socket, schemas: schemas)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    schemas =
      socket.assigns.schemas
      |> Enum.map(&Tools.toggle_select_single(&1, String.to_integer(id)))

      selected_count =
        Enum.filter(schemas, &(&1.selected))
        |> length

    {:noreply, assign(socket, schemas: schemas,
                              selected_count: selected_count)}
  end

  def handle_event("index", _,  socket) do
    selected_schema =
      Enum.filter(socket.assigns.schemas, &(&1.selected))
      |> hd

    index_path =
      Routes.databrowser_path(socket, :index, Phoenix.Naming.resource_name(selected_schema.title))
      {:noreply, push_redirect(socket, to: index_path)}
  end

  def handle_event("db_index", _, socket) do
    selected_schema =
      Enum.filter(socket.assigns.schemas, &(&1.selected))
      |> hd

    index_path =
      Routes.databrowser_path(socket, :db_indices, Phoenix.Naming.resource_name(selected_schema.title))
      {:noreply, push_redirect(socket, to: index_path)}
  end

  def handle_event("schema_definition", _, socket) do
    selected_schema =
      socket.assigns.schemas
      |> Enum.filter(&(&1.selected))
      |> hd

      index_path =
        Routes.databrowser_path(socket, :schema_definition, Phoenix.Naming.resource_name(selected_schema.title))
        {:noreply, push_redirect(socket, to: index_path)}
  end

  def render(assigns) do
    ~F"""
    <div>
      <Explorer id="schemas"
                title="Schemas"
                class="m-2 max-w-4xl"
                items={schema <- @schemas}
                {=@selected_count}
                format={:grid}>
        <ToolbarItem message="index"
                    title="Data"
                    when_selected_count={:one} />
        <ToolbarItem message="schema_definition"
                     title="Schema Definition"
                     when_selected_count={:one} />
        <ToolbarItem message="db_index"
                    title="Database Indices"
                    when_selected_count={:one} />
        <Col title="title">
          {schema.title |> Naming.model_in_plural}
        </Col>
      </Explorer>

      <div class="m-2 flex space-x-4">
        <LinkButton title="LiveDashboard"
                    to={live_dashboard_path(Endpoint, :home)}
                    class="bg-white hover:bg-gray-light border-gray" />

        <LinkButton title="Statistics"
                    to={maintenance_path(Endpoint, :stats)}
                    class="bg-white hover:bg-gray-light border-gray" />
      </div>
    </div>
    """
  end
end
