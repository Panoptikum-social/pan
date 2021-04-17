defmodule PanWeb.Live.Admin.Dashboard do
  alias PanWeb.Surface.Admin.Naming
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Surface.Admin.{Explorer, Col, Tools, ToolbarItem}

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
        schemas |>
        Enum.filter(&Map.get(&1, :selected)) |>
        Kernel.length

    {:noreply, assign(socket, schemas: schemas,
                              selected_count: selected_count)}
  end

  def handle_event("index", _,  socket) do
    selected_schema =
      socket.assigns.schemas
      |> Enum.filter(&Map.get(&1, :selected))
      |> List.first

    index_path =
      Routes.databrowser_path(socket, :index, Phoenix.Naming.resource_name(selected_schema.title))
      {:noreply, redirect(socket, to: index_path)}
  end

  def handle_event("db_index", _, socket) do
    selected_schema =
      socket.assigns.schemas
      |> Enum.filter(&Map.get(&1, :selected))
      |> List.first

      index_path =
        Routes.databrowser_path(socket, :db_indices, Phoenix.Naming.resource_name(selected_schema.title))
        {:noreply, redirect(socket, to: index_path)}
  end

  def render(assigns) do
    ~H"""
    <Explorer id="schemas"
              title="Schemas"
              class="m-2"
              items={{ schema <- @schemas }}
              selected_count={{ @selected_count }}>
      <ToolbarItem message="index"
                   title="Data"
                   when_selected_count={{ :one }} />
      <ToolbarItem message="db_index"
                   title="Database Index"
                   when_selected_count={{ :one }} />
      <Col title="Schema">
        {{ schema.title |> Naming.model_in_plural }}
      </Col>
    </Explorer>
    """
  end
end
