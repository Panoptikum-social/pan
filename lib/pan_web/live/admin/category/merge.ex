defmodule PanWeb.Live.Admin.Category.Merge do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}
  on_mount PanWeb.Live.Admin.Auth
  alias PanWeb.Category
  alias PanWeb.Surface.{Icon, Tree, EventButton}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, categories: Category.tree(), selected_from_id: nil, selected_into_id: nil)}
  end

  def handle_event("merge", _, %{assigns: assigns} = socket) do
    Category.merge(assigns.from, assigns.to)
    {:noreply, assign(socket, categories: Category.tree())}
  end

  def handle_event("selectFrom", %{"node-id" => selected_from_id}, socket) do
    {:noreply, assign(socket, selected_from_id: selected_from_id |> String.to_integer())}
  end

  def handle_event("selectInto", %{"node-id" => selected_into_id}, socket) do
    {:noreply, assign(socket, selected_into_id: selected_into_id |> String.to_integer())}
  end

  def render(assigns) do
    ~F"""
    <h2 class="text-3xl m-4">Merging categories</h2>

    <div class="flex m-4 space-x-4">
      <Tree id="fromTree"
            nodes={@categories}
            select="selectFrom"
            selected_id={@selected_from_id}/>
      <Tree id="intoTree"
            nodes={@categories}
            select="selectInto"
            selected_id={@selected_into_id} />

      <div>
        <EventButton event="merge">
          <Icon name="folder-heroicons-outline" />
          <Icon name="arrow-sm-right-heroicons-outline" />
          <Icon name="folder-heroicons-outline" />
          Merge Categories
        </EventButton>
      </div>
    </div>

    <script>
    function merge_selected(){
      var from_id = $("#tree1").treeview('getSelected')[0].categoryId
      var to_id = $("#tree2").treeview('getSelected')[0].categoryId
      window.location = "<%= category_url(@conn, :execute_merge) %>?from=" + from_id + "&to=" + to_id
    }
    </script>
    """
  end
end
