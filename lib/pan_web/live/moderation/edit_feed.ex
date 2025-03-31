defmodule PanWeb.Live.Moderation.EditFeed do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, :live_admin},
    container: {:div, class: "flex-1 w-full"}

  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Feed, Podcast}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => category_id, "feed_id" => feed_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    feed = Feed.get_by_id(feed_id)

    columns = [
      :id,
      :podcast_id,
      :self_link_title,
      :self_link_url,
      :next_page_url,
      :prev_page_url,
      :first_page_url,
      :last_page_url,
      :hub_link_url,
      :feed_generator,
      :etag,
      :last_modified,
      :trust_last_modified,
      :no_headers_available,
      :hash,
      :inserted_at,
      :updated_at
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
      {:ok, assign(socket, feed: feed, cols: cols, category_id: category_id)}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:saved, %{message: message}}, socket) do
    feed_grid_path =
      Routes.moderation_frontend_path(
        socket,
        :feed_grid,
        socket.assigns.category_id,
        socket.assigns.feed.podcast_id
      )

    {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: feed_grid_path)}
  end

  def render(%{error: "not_found"} = assigns) do
    ~F"""
    <div class="m-12">
      This podcast/category combination is not within your moderations.
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <RecordForm id={"record_form_feed_" <> Integer.to_string(@feed.id)}
    record = {@feed}
    model= {Feed}
    {=@cols} />
    """
  end
end
