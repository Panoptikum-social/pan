defmodule PanWeb.Live.Moderation.FeedGrid do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast, Feed}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Moderation.ModerationGrid
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => category_id, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    columns = [
      :id, :self_link_title, :self_link_url, :next_page_url, :prev_page_url, :first_page_url,
      :last_page_url, :hub_link_url, :feed_generator, :etag, :last_modified, :trust_last_modified,
      :no_headers_available, :hash, :inserted_at, :updated_at
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

    feed_ids = Feed.ids_by_category_id_and_podcast_id(category_id, podcast_id)
    podcast_ids = Podcast.ids_by_category_id(category_id)

    if moderation && Enum.member?(podcast_ids, String.to_integer(podcast_id)) do
      {:ok, assign(socket, podcast: podcast, category_id: category_id, cols: cols, feed_ids: feed_ids) }
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:edit_feed, feed_id}, socket) do
    category_id = socket.assigns[:category_id]
    edit_feed_path = Routes.moderation_frontend_path(socket, :edit_feed, category_id, feed_id)
    {:noreply, push_redirect(socket, to: edit_feed_path)}
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
    <div class="m-4">
      <h1 class="text-2xl">
        Podcast {@podcast.title} / Feeds
      </h1>

      <ModerationGrid id="episodes_table"
        heading={"Listing Feeds for Podcast #{@podcast.title}"}
        model={Feed}
        cols={@cols}
        search_filter={{:id, @feed_ids}}
        buttons={[:pagination, :number_of_records, :edit_feed, :search]} />
    </div>
    """
  end
end
