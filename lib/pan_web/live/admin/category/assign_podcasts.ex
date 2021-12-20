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
       add_ids: [],
       assigned_page: 1,
       assigned_per_page: 10,
       assigned_sort_by: :id,
       assigned_sort_order: :asc,
       assigned_podcasts: [],
       unassigned_page: 1,
       unassigned_per_page: 10,
       unassigned_sort_by: :id,
       unassigned_sort_order: :asc,
       unassigned_podcasts: []
     )}
  end

  defp fetch(
         %{
           assigns: %{
             selected_id: selected_id,
             assigned_page: assigned_page,
             assigned_per_page: assigned_per_page,
             assigned_sort_by: assigned_sort_by,
             assigned_sort_order: assigned_sort_order,
             unassigned_page: unassigned_page,
             unassigned_per_page: unassigned_per_page,
             unassigned_sort_by: unassigned_sort_by,
             unassigned_sort_order: unassigned_sort_order
           }
         } = socket
       ) do

    assigned_podcasts =
      Podcast.assigned_for_assign_podcast(
        selected_id,
        assigned_page,
        assigned_per_page,
        assigned_sort_by,
        assigned_sort_order
      )

    unassigned_podcasts =
      Podcast.unassigned_for_assign_podcast(
        selected_id,
        unassigned_page,
        unassigned_per_page,
        unassigned_sort_by,
        unassigned_sort_order
      )

    assign(socket, assigned_podcasts: assigned_podcasts, unassigned_podcasts: unassigned_podcasts)
  end

  def handle_event(
        "sort_assigned",
        %{"sort-by" => assigned_sort_by, "sort-order" => assigned_sort_order},
        socket
      ) do
    {:noreply,
     assign(socket,
       assigned_sort_by: assigned_sort_by |> String.to_atom(),
       assigned_sort_order: assigned_sort_order |> String.to_atom()
     )
     |> fetch}
  end

  def handle_event(
        "sort_unassigned",
        %{"sort-by" => unassigned_sort_by, "sort-order" => unassigned_sort_order},
        socket
      ) do
    IO.inspect(unassigned_sort_order |> String.to_atom())

    {:noreply,
     assign(socket,
       unassigned_sort_by: unassigned_sort_by |> String.to_atom(),
       unassigned_sort_order: unassigned_sort_order |> String.to_atom()
     )
     |> fetch}
  end

  def handle_event("select_category", %{"node-id" => node_id}, %{assigns: assigns} = socket) do
    if assigns.selected_id != String.to_integer(node_id) do
      {:noreply, assign(socket, :selected_id, String.to_integer(node_id)) |> fetch}
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
                     cols={[%{field: :id, type: :id, label: "Id"},
                            %{field: :title, type: :string, label: "Title of assigned podcast"}]}
                     model={PanWeb.Podcast}
                     records={@assigned_podcasts}
                     buttons={[]}
                     sort="sort_assigned"
                     sort_by={@assigned_sort_by}
                     sort_order={@assigned_sort_order}
                     search="search_assigned"
                     select="select_assigned"
                     cycle_search_mode="cycle_search_mode_assigned" />
          <p>Select category first, then select podcasts to remove</p>

          <h3 class="text-2xl">Podcasts unassigned</h3>
          <DataTable id="unassigned_podcasts"
                     cols={[%{field: :id, type: :id, label: "Id"},
                            %{field: :title, type: :string, label: "Title of assigned podcast"}]}
                     model={PanWeb.Podcast}
                     records={@unassigned_podcasts}
                     buttons={[]}
                     sort="sort_unassigned"
                     sort_by={@unassigned_sort_by}
                     sort_order={@unassigned_sort_order}
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
