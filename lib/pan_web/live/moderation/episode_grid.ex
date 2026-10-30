defmodule PanWeb.Live.Moderation.EpisodeGrid do
  use PanWeb, :moderation_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast, Episode}
  alias PanWeb.Admin.Naming
  alias PanWeb.Admin.ModerationGrid
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => slug, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_community_slug_and_user_id(slug, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    columns = [
      :id,
      :title,
      :publishing_date,
      :guid,
      :duration,
      :full_text,
      :inserted_at,
      :updated_at
    ]

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(Episode, &1),
          searchable: true,
          sortable: true
        }
      )

    category_id = moderation && moderation.community.category_id

    if moderation &&
         Enum.member?(Podcast.ids_by_category_id(category_id), String.to_integer(podcast_id)) do
      {:ok,
       assign(socket,
         community: moderation.community,
         podcast: podcast,
         cols: cols,
         episode_ids: Episode.ids_by_category_id_and_podcast_id(category_id, podcast_id)
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:edit_episode, episode_id}, socket) do
    community = socket.assigns.community

    edit_episode_path =
      Routes.moderation_frontend_path(socket, :edit_episode, community, episode_id)

    {:noreply, push_navigate(socket, to: edit_episode_path)}
  end

  def handle_info({:show_in_frontend, episode_id}, socket) do
    show_podcast_path = Routes.episode_frontend_path(socket, :show, episode_id)
    {:noreply, redirect(socket, to: show_podcast_path)}
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
        Podcast {@podcast.title} / Episodes
      </h1>

      <.live_component
        module={ModerationGrid}
        id="episodes_table"
        heading={"Listing Episodes for Podcast #{@podcast.title}"}
        model={Episode}
        cols={@cols}
        search_filter={{:id, @episode_ids}}
        buttons={[:pagination, :show_in_frontend, :edit_episode, :number_of_records, :search]}
      />
    </div>
    """
  end
end
