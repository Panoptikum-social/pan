defmodule PanWeb.Live.Moderation.EditFeed do
  use PanWeb, :admin_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  import Ecto.Query, only: [from: 2]
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Moderation, Podcast}
  alias PanWeb.Admin.Naming
  alias PanWeb.Component.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => category_id, "feed_id" => feed_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    feed = Feed.get_by_id(feed_id)

    # Deliberately not the full Feed schema — a moderator-facing allowlist.
    # Excluded: :id/:podcast_id/:inserted_at/:updated_at (primary/foreign key
    # + Ecto-managed timestamps), :next_page_url/:prev_page_url/
    # :first_page_url/:last_page_url/:hub_link_url/:feed_generator (parsed
    # out of the feed XML itself, not meaningfully hand-edited), and
    # :etag/:last_modified/:trust_last_modified/:no_headers_available/:hash
    # (HTTP caching/fingerprinting bookkeeping, internal). :self_link_title
    # and :self_link_url stay editable so a moderator can fix a feed's URL
    # by hand if it moved.
    columns = [
      :self_link_title,
      :self_link_url
    ]

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(Feed, &1),
          searchable: true,
          sortable: true
        }
      )

    podcast_ids = Podcast.ids_by_category_id(category_id)

    if moderation && Enum.member?(podcast_ids, feed.podcast_id) do
      {:ok,
       assign(socket,
         feed: feed,
         cols: cols,
         category_id: category_id,
         alternate_feeds: previous_urls(feed)
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  # The form saves the feed as it is; a changed URL gets the same treatment
  # as a restored one (old URL kept, caching reset, updated soon).
  def handle_info({:saved, %{message: message}}, socket) do
    old_feed = socket.assigns.feed
    new_url = Feed.get_by_id(old_feed.id).self_link_url

    message =
      if new_url != old_feed.self_link_url do
        Feed.change_url(old_feed, new_url)
        message <> " The next update shows whether the new URL works."
      else
        message
      end

    feed_grid_path =
      Routes.moderation_frontend_path(
        socket,
        :feed_grid,
        socket.assigns.category_id,
        socket.assigns.feed.podcast_id
      )

    {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: feed_grid_path)}
  end

  def handle_event("restore", %{"url" => url}, socket) do
    feed = socket.assigns.feed

    socket =
      case Feed.restore_alternate(feed, url) do
        {:ok, feed} ->
          socket
          |> assign(feed: feed, alternate_feeds: previous_urls(feed))
          |> put_flash(
            :info,
            "The feed URL is #{url} again, the next update shows whether it works."
          )

        {:error, message} when is_binary(message) ->
          put_flash(socket, :error, message)

        {:error, _changeset} ->
          put_flash(socket, :error, "The feed URL could not be restored.")
      end

    {:noreply, socket}
  end

  defp previous_urls(feed) do
    from(a in AlternateFeed,
      where: a.feed_id == ^feed.id and a.url != ^feed.self_link_url,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      This podcast/category combination is not within your moderations.
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={RecordForm}
      id={"record_form_feed_" <> Integer.to_string(@feed.id)}
      record={@feed}
      model={Feed}
      cols={@cols}
    />

    <form :if={@alternate_feeds != []} phx-submit="restore" class="m-4 flex gap-2 items-center">
      <span>Restore a previous URL</span>
      <select name="url" class="select select-sm max-w-xl">
        <option :for={alternate <- @alternate_feeds} value={alternate.url}>
          {Calendar.strftime(alternate.inserted_at, "%Y-%m-%d")} {alternate.url}
        </option>
      </select>
      <button
        type="submit"
        data-confirm="Make the selected URL the feed URL again?"
        class="btn btn-primary btn-sm"
      >
        Restore
      </button>
    </form>
    """
  end
end
