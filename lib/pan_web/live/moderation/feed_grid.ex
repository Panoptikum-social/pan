defmodule PanWeb.Live.Moderation.FeedGrid do
  use PanWeb, :moderation_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast, Feed}
  alias PanWeb.Admin.Naming
  alias PanWeb.Admin.ModerationGrid
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => slug, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_community_slug_and_user_id(slug, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    columns = [
      :id,
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

    category_id = moderation && moderation.community.category_id

    if moderation &&
         Enum.member?(Podcast.ids_by_category_id(category_id), String.to_integer(podcast_id)) do
      {:ok,
       assign(socket,
         podcast: podcast,
         community: moderation.community,
         cols: cols,
         feed_ids: Feed.ids_by_category_id_and_podcast_id(category_id, podcast_id)
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:edit_feed, feed_id}, socket) do
    community = socket.assigns.community
    edit_feed_path = Routes.moderation_frontend_path(socket, :edit_feed, community, feed_id)
    {:noreply, push_navigate(socket, to: edit_feed_path)}
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
    <div class="m-4">
      <h1 class="text-2xl">
        Podcast {@podcast.title} / Feeds
      </h1>

      <.live_component
        module={ModerationGrid}
        id="episodes_table"
        heading={"Listing Feeds for Podcast #{@podcast.title}"}
        model={Feed}
        cols={@cols}
        search_filter={{:id, @feed_ids}}
        buttons={[:pagination, :number_of_records, :edit_feed, :search]}
      />
    </div>
    """
  end
end
