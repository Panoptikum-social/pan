defmodule PanWeb.Live.Admin.Podcast.Stale do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "m-4"}

  on_mount PanWeb.Live.Admin.Auth
  alias PanWeb.{Podcast, Endpoint}
  alias PanWeb.Surface.{LinkButton, Admin.SortLink}
  import PanWeb.Router.Helpers

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(:pan_pubsub, "admin")
    {:ok, assign(socket, sort_order: :asc, sort_by: :next_update ) |> fetch()}
  end

  defp fetch(%{assigns: %{sort_by: sort_by, sort_order: sort_order}} = socket) do
    assign(socket,
      stale_podcasts: Podcast.stale(sort_by, sort_order, 10),
      stale_podcasts_count: Podcast.count_stale()
    )
  end

  def handle_info(payload, socket) do
    {:noreply, push_event(socket, "notification", payload) |> fetch()}
  end

  def handle_event("sort", %{"sort-by" => sort_by, "sort-order" => sort_order}, socket) do
    {:noreply, assign(socket,
      sort_by: String.to_atom(sort_by),
      sort_order: String.to_atom(sort_order)
    )|> fetch()}
  end

  def handle_event("trigger-update", _, socket) do
    Task.start(fn ->
      Podcast.get_one_stale()
      |> Podcast.import_stale()
    end)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <p class="flex justify-end space-x-4"
       phx-hook="Notification"
       id="notification-hook-target">
      <button :on-click="trigger-update"
              class="border border-gray-darker text-white text-sm rounded bg-info hover:bg-info-light px-2 py-1">
        Episode import
      </button>
      <LinkButton title="Factory"
                  to={podcast_path(Endpoint, :factory)}
                  class="border-gray text-white bg-primary hover:bg-primary-light" />
    </p>


    <h2 class="text-2xl">{@stale_podcasts_count} stale podcasts</h2>

    <table cellpadding="4" class="my-4">
      <thead>
        <tr>
          <th class="border border-gray-light">
            <SortLink field={:id} click="sort" {=@sort_order} {=@sort_by}>
              ID
            </SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:title} click="sort" {=@sort_order} {=@sort_by}>
              Title
            </SortLink>
          </th>
          <th class="border border-gray-light">
          <SortLink field={:updated_at} click="sort" {=@sort_order} {=@sort_by}>
            Updated at
            </SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:update_intervall} click="sort" {=@sort_order} {=@sort_by}>
              Update intervall
            </SortLink>
          </th>
          <th class="border border-gray-light">
            <SortLink field={:next_update} click="sort" {=@sort_order} {=@sort_by}>
              Next update
            </SortLink>
          </th>
          <th class="border border-gray-light">
          <SortLink field={:failure_count} click="sort" {=@sort_order} {=@sort_by}>
            Failure count
          </SortLink>
          </th>
          <th class="border border-gray-light">Feed url</th>
          <th class="border border-gray-light">Actions</th>
        </tr>
      </thead>
      <tbody>
        {#for podcast <- @stale_podcasts}
          <tr>
            <td class="border border-gray-light">{podcast.id}</td>
            <td class="border border-gray-light">{podcast.title}</td>
            <td class="border border-gray-light whitespace-nowrap">{podcast.updated_at |> Timex.format!("{ISOdate} {h24}:{m}:{s}")}</td>
            <td class="border border-gray-light">{podcast.update_intervall}</td>
            <td class="border border-gray-light whitespace-nowrap">{podcast.next_update |> Timex.format!("{ISOdate} {h24}:{m}:{s}")}</td>
            <td class="border border-gray-light">{podcast.failure_count}</td>
            <td class="border border-gray-light">{podcast.feed_url}</td>
            <td class="border border-gray-light"><nobr>
              <LinkButton title="Show"
                          to={databrowser_path(Endpoint, :show, "podcast", podcast.id)}
                          class="border-gray text-black bg-default hover:bg-default-light" />
              <LinkButton title="Edit"
                          to={databrowser_path(Endpoint, :edit, "podcast", podcast.id)}
                          class="border-gray text-white bg-warning hover:bg-warning-light" />
              <LinkButton title="Pause"
                          to={podcast_path(Endpoint, :pause, podcast.id)}
                          class="border-gray text-white bg-primary hover:bg-primary-light" />
            </nobr></td>
          </tr>
        {/for}
      </tbody>
    </table>
    """
  end
end
