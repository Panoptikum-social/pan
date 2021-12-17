defmodule PanWeb.Live.Admin.Category.AssignPodcasts do
  use Surface.LiveView
  on_mount PanWeb.Live.Admin.Auth
  alias PanWeb.{Category, Podcast}
  alias PanWeb.Surface.{Icon, Tree}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       categories: Category.tree_for_assign_podcasts(),
       podcasts: Podcast.all(),
       selected_id: 0
     )}
  end

  def handle_event("select", %{"node-id" => node_id}, %{assigns: assigns} = socket) do
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

      <div class="flex">
        <div>
          <h3 class="text-2xl">Select category</h3>
          <Tree id="category_tree"
                nodes={@categories}
                class="m-4"
                selected_id={@selected_id}
                select="select" />
        </div>

        <div>
          <h3>Podcasts assigned</h3>
          <table id="assigned_podcasts"
                class="table table-striped table-condensed table-bordered dataTable"
                cellspacing="0"
                width="100%">
          </table>

          <hr/>

          <h3>Podcasts unassigned</h3>
          <table id="unassigned_podcasts"
                class="table table-striped table-condensed table-bordered table-dataTable"
                cellspacing="0"
                width="100%">
          </table>

          <a onclick="execute_assign()"
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

    <script>
      $(function() {
        $('#assigned_podcasts').DataTable({
          serverSide: false,
          data: [{ id: 0,
                  title: "Select category first, then select podcasts to remove." +
                          " CTRL + Click to select several!" }],
          columns: [
            { data: 'id', title: "ID"},
            { data: 'title', title: "Title of podcasts assigned" }
          ],
          select: true
        })a component may render more than one DOM element s
          data: [{ id: 0,
                  title: "Select category first, then select podcasts to add." +
                          " CTRL + Click to select several!" }],
          columns: [
            { data: 'title', title: "Title of unassigned podcasts" },
            { data: 'id', title: "ID"}
          ],
          select: true
        })
      })

      function execute_assign(){
        var categoryID = $('#category_tree').treeview('getSelected')[0].categoryId
        var delete_ids = $('#assigned_podcasts').DataTable()
                                                .rows({ selected: true })
                                                .data()
                                                .toArray()
                                                .map(function(podcast) {return podcast.id})
        var add_ids =  $('#unassigned_podcasts').DataTable()
                                                .rows({ selected: true })
                                                .data()
                                                .toArray()
                                                .map(function(podcast) {return podcast.id})

        $.ajax({
          type: "POST",
          url: "<%= category_url(@conn, :execute_assign) %>",
          data: { category_id: categoryID,
                  delete_ids: delete_ids,
                  add_ids: add_ids},
          headers: {"X-CSRF-TOKEN": "<%= get_csrf_token() %>" },
          success: function(data) {
            get_podcasts()
          }
        })
      }

      function get_podcasts(){
        var categoryID = $('#category_tree').treeview('getSelected')[0].categoryId
        $.ajax({
          url: "/api/categories/" + categoryID + "/get_podcasts",
          success: function (data) {
            $('#assigned_podcasts').dataTable().fnClearTable();
            if (data["podcasts_assigned"].length > 0) {
              $('#assigned_podcasts').dataTable().fnAddData(data["podcasts_assigned"]);
            }
            $('#unassigned_podcasts').dataTable().fnClearTable();
            $('#unassigned_podcasts').dataTable().fnAddData(data["podcasts_unassigned"]);
          }
        })
      }
    </script>
    """
  end
end
