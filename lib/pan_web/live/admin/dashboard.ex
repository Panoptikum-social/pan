defmodule PanWeb.Live.Admin.Dashboard do
  use PanWeb, :admin_live_view
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Admin.Tools
  alias PanWeb.Admin.Explorer
  alias PanWeb.Admin.Naming
  alias PanWeb.Component.LinkButton
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    schemas =
      Naming.schemas()
      |> Enum.map(&%{title: &1})

    {:ok,
     assign(socket,
       id: "admin_dashboard",
       schemas: schemas,
       selected_count: 0
     )}
  end

  def handle_info({:items, schemas}, socket) do
    {:noreply, assign(socket, schemas: schemas)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    schemas =
      socket.assigns.schemas
      |> Enum.map(&Tools.toggle_select_single(&1, String.to_integer(id)))

    selected_count =
      Enum.filter(schemas, & &1.selected)
      |> length

    {:noreply,
     assign(socket,
       schemas: schemas,
       selected_count: selected_count
     )}
  end

  def handle_event("index", _, socket) do
    selected_schema =
      Enum.filter(socket.assigns.schemas, & &1.selected)
      |> hd

    index_path =
      Routes.databrowser_path(Endpoint, :index, Phoenix.Naming.resource_name(selected_schema.title))

    {:noreply, push_navigate(socket, to: index_path)}
  end

  def handle_event("db_index", _, socket) do
    selected_schema =
      Enum.filter(socket.assigns.schemas, & &1.selected)
      |> hd

    index_path =
      Routes.databrowser_path(
        Endpoint,
        :db_indices,
        Phoenix.Naming.resource_name(selected_schema.title)
      )

    {:noreply, push_navigate(socket, to: index_path)}
  end

  def handle_event("schema_definition", _, socket) do
    selected_schema =
      socket.assigns.schemas
      |> Enum.filter(& &1.selected)
      |> hd

    index_path =
      Routes.databrowser_path(
        Endpoint,
        :schema_definition,
        Phoenix.Naming.resource_name(selected_schema.title)
      )

    {:noreply, push_navigate(socket, to: index_path)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={Explorer}
                id="schemas"
                title="Schemas"
                class="m-2 max-w-4xl"
                items={@schemas}
                selected_count={@selected_count}
                format={:grid}>
        <:toolbar_items message="index" title="Data" when_selected_count={:one} />
        <:toolbar_items message="schema_definition" title="Schema Definition" when_selected_count={:one} />
        <:toolbar_items message="db_index" title="Database Indices" when_selected_count={:one} />
        <:cols title="title" :let={schema}>
          {schema.title |> Naming.model_in_plural}
        </:cols>
      </.live_component>

      <div class="-mt-2 mx-2 flex space-x-4 border-x border-gray p-2 max-w-4xl">
        <LinkButton.render title="Live Dashboard"
                    to={live_dashboard_path(Endpoint, :home)}
                    class="btn-ghost" />
        <LinkButton.render title="Statistics"
                    to={maintenance_path(Endpoint, :stats)}
                    class="btn-ghost" />
        <LinkButton.render title="Catch up missing thumbnailed booleans"
                    to={maintenance_path(Endpoint, :catch_up_thumbnailed)}
                    class="btn-warning" />
        <LinkButton.render title="Trigger exception notification"
                    to={maintenance_path(Endpoint, :exception_notification)}
                    class="btn-success" />
      </div>
      <div class="mx-2 flex space-x-4 items-center border border-gray p-2 max-w-4xl">
        <span class="font-mono">Full text Search</span>
        <LinkButton.render title="Push Missing"
                    to={search_path(Endpoint, :push_missing)}
                    class="btn-warning" />
        <LinkButton.render title="Migrate Manticore Search Indices"
                    to={search_path(Endpoint, :migrate)}
                    class="btn-error"
                    opts={[data: [confirm: "Are you sure?"]]} />
        <LinkButton.render title="Delete Orphaned Index Entries"
                    to={search_path(Endpoint, :delete_orphans)}
                    class="btn-error"
                    opts={[data: [confirm: "Are you sure?"]]} />
        <LinkButton.render title="Reset all Records"
                    to={search_path(Endpoint, :reset_all)}
                    class="btn-error"
                    opts={[data: [confirm: "Are you sure?"]]} />
      </div>
    </div>
    """
  end
end
