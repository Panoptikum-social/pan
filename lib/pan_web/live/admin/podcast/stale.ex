defmodule PanWeb.Live.Admin.Podcast.Stale do
  use PanWeb, :admin_live_view
  alias PanWeb.{Podcast, Endpoint}
  alias PanWeb.Admin.SortLink
  alias PanWeb.Component.LinkButton
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(:pan_pubsub, "admin")
    Process.send_after(self(), :refresh, 5 * 1000)
    {:ok, assign(socket, sort_order: :asc, sort_by: :next_update) |> fetch()}
  end

  defp fetch(%{assigns: %{sort_by: sort_by, sort_order: sort_order}} = socket) do
    assign(socket,
      stale_podcasts: Podcast.stale(sort_by, sort_order, 10),
      stale_podcasts_count: Podcast.count_stale()
    )
  end

  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, 60 * 1000)
    {:noreply, socket |> fetch()}
  end

  def handle_info(payload, socket) do
    {:noreply, push_event(socket, "notification", payload)}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    {:noreply,
     assign(socket,
       sort_by: String.to_atom(sort_by),
       sort_order: String.to_atom(sort_order)
     )
     |> fetch()}
  end

  def handle_event("trigger-update", _, socket) do
    Task.start(fn ->
      trigger_update()
    end)

    {:noreply, socket}
  end

  defp trigger_update() do
    Podcast.get_one_stale()
    |> Podcast.import_stale()

    trigger_update()
  end

  def vienna_string(naive_date_time) do
    naive_date_time
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Vienna")
    |> Calendar.strftime("%c")
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <button id="notification-hook-target"
              phx-hook="Notification"
              phx-click="trigger-update"
              class="btn btn-info btn-sm float-right">
        Episode import
      </button>

      <h1 class="text-3xl">{@stale_podcasts_count} stale podcasts</h1>

      <p>This view is auto-refreshing every 60 seconds.</p>

      <table class="table table-zebra table-xs my-4 w-auto">
        <thead>
          <tr>
            <th><SortLink.render field={:id} click="sort" sort_order={@sort_order} sort_by={@sort_by}>ID</SortLink.render></th>
            <th><SortLink.render field={:title} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Title</SortLink.render></th>
            <th><SortLink.render field={:updated_at} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Updated at 🎡</SortLink.render></th>
            <th><SortLink.render field={:update_intervall} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Update intervall</SortLink.render></th>
            <th><SortLink.render field={:next_update} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Next update 🎡</SortLink.render></th>
            <th><SortLink.render field={:failure_count} click="sort" sort_order={@sort_order} sort_by={@sort_by}>Failure count</SortLink.render></th>
            <th>Feed url</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={podcast <- @stale_podcasts}>
            <td class="text-right">
              <LinkButton.render title={podcast.id}
                          to={databrowser_path(Endpoint, :show, "podcast", podcast.id)}
                          class="btn-primary" /></td>
            <td>{podcast.title}</td>
            <td class="whitespace-nowrap">{podcast.updated_at |> vienna_string()}</td>
            <td>{podcast.update_intervall}</td>
            <td class="whitespace-nowrap">{podcast.next_update |> vienna_string()}</td>
            <td>{podcast.failure_count}</td>
            <td>{podcast.feed_url}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
