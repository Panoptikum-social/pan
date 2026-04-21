defmodule PanWeb.Live.Admin.Category.Merge do
  use PanWeb, :admin_live_view
  alias PanWeb.Category
  alias PanWeb.Component.{Tree, EventButton, Icon}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree(), from_id: nil, into_id: nil)}
  end

  def handle_event("merge", _, %{assigns: assigns} = socket) do
    Category.merge(assigns.from_id, assigns.into_id)
    {:noreply, assign(socket, categories: Category.tree(), from_id: nil, into_id: nil)}
  end

  def handle_event("selectFrom", %{"node-id" => from_id}, socket) do
    {:noreply, assign(socket, from_id: from_id |> String.to_integer())}
  end

  def handle_event("selectInto", %{"node-id" => into_id}, socket) do
    {:noreply, assign(socket, into_id: into_id |> String.to_integer())}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl m-4">Merging categories</h1>

    <div class="flex m-4 space-x-4">
      <.live_component module={Tree}
            id="fromTree"
            nodes={@categories}
            select="selectFrom"
            selected_id={@from_id} />
      <.live_component module={Tree}
            id="intoTree"
            nodes={@categories}
            select="selectInto"
            selected_id={@into_id} />

      <div>
        <EventButton.render event="merge">
          <Icon.render name="folder-heroicons-outline" />
          <Icon.render name="arrow-sm-right-heroicons-outline" />
          <Icon.render name="folder-heroicons-outline" />
          Merge Categories
        </EventButton.render>
      </div>
    </div>
    """
  end
end
