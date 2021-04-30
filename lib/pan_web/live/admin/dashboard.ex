defmodule PanWeb.Live.Admin.Dashboard do
  alias Surface.Components.Link
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Surface.Admin.{Explorer, Col, Tools, ToolbarItem, Naming}

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
    ~H"""
    <div>
      <Explorer id="schemas"
                title="Schemas"
                class="m-2 max-w-2xl"
                items={{ schema <- @schemas }}
                selected_count={{ @selected_count }}
                format={{ :grid }}
                grid_columns=4>
        <ToolbarItem message="index"
                    title="Data"
                    when_selected_count={{ :one }} />
        <ToolbarItem message="schema_definition"
                    title="Schema Definition"
                    when_selected_count={{ :one }} />
        <ToolbarItem message="db_index"
                    title="Database Indices"
                    when_selected_count={{ :one }} />
        <Col title="title">
          {{ schema.title |> Naming.model_in_plural }}
        </Col>
      </Explorer>

      <div class="m-4">
        <h2 class="text-2xl">Podcasts</h2>
        <ul class="list-disc m-4">
          <li>
            <Link label="Factory"
                  to={{ Routes.podcast_path(@socket, :factory) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Orphans"
                  to={{ Routes.podcast_path(@socket, :orphans) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Retirement"
                  to={{ Routes.podcast_path(@socket, :retirement) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Stale"
                  to={{ Routes.podcast_path(@socket, :stale) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Duplicates"
                  to={{ Routes.podcast_path(@socket, :duplicates) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
        </ul>

        <h2 class="text-2xl">Episodes</h2>
        <ul class="list-disc m-4">
          <li>
            <Link label="Remove duplicates"
                  to={{ Routes.episode_path(@socket, :remove_duplicates) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
        </ul>

        <h2 class="text-2xl">Personas</h2>
        <ul class="list-disc m-4">
          <li>
            <Link label="Merge Candidates"
                  to={{ Routes.persona_path(@socket, :merge_candidates) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
        </ul>

        <h2 class="text-2xl">Users</h2>
        <ul class="list-disc m-4">
          <li>
            <Link label="Merge Users"
                  to={{ Routes.user_path(@socket, :merge) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Manifest Users"
                  to={{ Routes.manifestation_path(@socket, :manifest) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
        </ul>

        <h2 class="text-2xl">Feed Backlog</h2>
        <ul class="list-disc m-4">
          <li>
            <Link label="Import 100"
                  to={{ Routes.feed_backlog_path(@socket, :import_100) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Subscribe All"
                  to={{ Routes.feed_backlog_path(@socket, :subscribe) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Subscribe 50"
                  to={{ Routes.feed_backlog_path(@socket, :subscribe50) }}
                  class="text-link hover:text-link-dark underline"/>
          </li>
          <li>
            <Link label="Delete All (from Itunes user)"
                  to={{ Routes.feed_backlog_path(@socket, :delete_all) }}
                  class="text-link hover:text-link-dark underline"
                  opts={{ method: :delete,
                          data: [confirm: "Are you sure?"] }} />
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
