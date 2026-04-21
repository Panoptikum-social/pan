defmodule PanWeb.Live.Admin.Podcast.Retirement do
  use PanWeb, :admin_live_view
  alias PanWeb.Podcast
  alias PanWeb.Admin.IndexGrid

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-2xl m-4">Retirement</h1>

    <div class="bg-info-light/50 rounded-lg border border-gray-dark p-2 m-4">
      <p>Select Podcast and use [Edit] to change the retirement flag. Beware: after saving the edited record, you end up in the databrowser, not here!</p>
    </div>

    <.live_component module={IndexGrid}
               id="podcast-indexgrid"
               heading="Listing Pocasts"
               model={Podcast}
               cols={[
                 %{field: :id, label: "Id", searchable: true, sortable: true, type: :id},
                 %{field: :title, label: "Title", type: :string, searchable: true, sortable: true},
                 %{field: :retired, label: "Retired", type: :string, searchable: true, sortable: true},
                 %{field: :last_build_date, label: "Last build date", type: :naive_datetime, searchable: true, sortable: true},
                 %{field: :latest_episode_publishing_date, label: "Latest episode publishing date", type: :naive_datetime, searchable: true, sortable: true}
               ]}
               buttons={[:show, :edit, :pagination, :number_of_records, :search]} />
    """
  end
end
