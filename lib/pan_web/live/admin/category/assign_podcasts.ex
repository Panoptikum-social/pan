defmodule PanWeb.Live.Admin.Category.AssignPodcasts do
  use Surface.LiveView
  on_mount PanWeb.Live.Admin.Auth
  alias PanWeb.{Category, Podcast}
  alias PanWeb.Surface.{Icon, Tree}
  alias PanWeb.Surface.Admin.DataTable

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       categories: Category.tree_for_assign_podcasts(),
       podcasts: Podcast.all(),
       selected_id: 0,
       delete_ids: [],
       add_ids: []
     )}
  end

  def handle_event("select_category", %{"node-id" => node_id}, %{assigns: assigns} = socket) do
    if assigns.selected_id != String.to_integer(node_id) do
      {:noreply, assign(socket, :selected_id, String.to_integer(node_id))}
    else
      {:noreply, assign(socket, :selected_id, 0)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      <h2 class="text-3xl">Assigning podcasts to categories</h2>

      <div class="flex my-4">
        <div>
          <h3 class="text-2xl">Select category</h3>
          <Tree id="category_tree"
                nodes={@categories}
                class="m-4"
                selected_id={@selected_id}
                select="select_category" />
        </div>

        <div class="flex flex-col space-y-4">
          <h3 class="text-2xl">Podcasts assigned</h3>
          <DataTable id="assigned_podcasts"
                     cols={[%{field: :id, type: :id, label: "Id"}, %{field: :title, type: :string, label: "Title of assigned podcast"}]}
                     model={PanWeb.Podcast}
                     buttons={[]}
                     sort="sort_assigned"
                     search="search_assigned"
                     select="select_assigned"
                     cycle_search_mode="cycle_search_mode_assigned" />
          <p>Select category first, then select podcasts to remove</p>

          <h3 class="text-2xl">Podcasts unassigned</h3>
          <DataTable id="unassigned_podcasts"
                     cols={[%{field: :id, type: :id, label: "Id"}, %{field: :title, type: :string, label: "Title of assigned podcast"}]}
                     model={PanWeb.Podcast}
                     buttons={[]}
                     sort="sort_unassigned"
                     search="search_unassigned"
                     select="select_unassigned"
                     cycle_search_mode="cycle_search_mode_unassigned" />
          <p>Select category first, then select podcasts to add</p>

          <a :on-click="execute_assign"
             phx-category-id={@selected_id}
             phx-delete-ids={@delete_ids}
             phx-add-ids={@add_ids}
            class="border border-solid inline-block shadow m-4 py-1 px-2 rounded text-sm bg-info
                   hover:bg-info-light text-white border-gray-dark">
            <Icon name="podcast-lineawesome-solid" />
            <Icon name="arrow-sm-right-heroicons-outline" />
            <Icon name="folder-open-heroicons-outline" />
            <Icon name="arrow-sm-right-heroicons-outline" />
            <Icon name="podcast-lineawesome-solid" /> &nbsp;
            Update Assignments
          </a>
        </div>
      </div>
    </div>
    """
  end
end
