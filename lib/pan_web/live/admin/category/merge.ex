defmodule PanWeb.Live.Admin.Category.Merge do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  on_mount {PanWeb.Live.Auth, :admin}
  alias PanWeb.Category
  alias PanWeb.Surface.{Icon, Tree, EventButton}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree(), from_id: nil, into_id: nil)}
  end

  def handle_event("merge", _, %{assigns: assigns} = socket) do
    Category.merge(assigns.from_id, assigns.into_id)
    {:noreply, assign(socket, categories: Category.tree())}
  end

  def handle_event("selectFrom", %{"node-id" => from_id}, socket) do
    {:noreply, assign(socket, from_id: from_id |> String.to_integer())}
  end

  def handle_event("selectInto", %{"node-id" => into_id}, socket) do
    {:noreply, assign(socket, into_id: into_id |> String.to_integer())}
  end

  def render(assigns) do
    ~F"""
    <h1 class="text-3xl m-4">Merging categories</h1>

    <div class="flex m-4 space-x-4">
      <Tree id="fromTree"
            nodes={@categories}
            select="selectFrom"
            selected_id={@from_id}/>
      <Tree id="intoTree"
            nodes={@categories}
            select="selectInto"
            selected_id={@into_id} />

      <div>
        <EventButton event="merge">
          <Icon name="folder-heroicons-outline" />
          <Icon name="arrow-sm-right-heroicons-outline" />
          <Icon name="folder-heroicons-outline" />
          Merge Categories
        </EventButton>
      </div>
    </div>
    """
  end
end
