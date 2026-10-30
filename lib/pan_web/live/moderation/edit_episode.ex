defmodule PanWeb.Live.Moderation.EditEpisode do
  use PanWeb, :admin_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Moderation, Podcast, Episode}
  alias PanWeb.Admin.Naming
  alias PanWeb.Component.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => slug, "episode_id" => episode_id}, session, socket) do
    moderation = Moderation.get_by_community_slug_and_user_id(slug, session["user_id"])
    episode = Episode.get_by_id(episode_id)

    # Deliberately not the full Episode schema — a moderator-facing allowlist.
    # Excluded: :id/:podcast_id/:inserted_at/:updated_at (primary/foreign key
    # + Ecto-managed timestamps), :full_text (internal search-index flag), and
    # :guid (feed-derived unique id, not meaningfully hand-edited).
    columns = [
      :title,
      :link,
      :publishing_date,
      :description,
      :shownotes,
      :payment_link_title,
      :payment_link_url,
      :deep_link,
      :duration,
      :subtitle,
      :summary,
      :image_title,
      :image_url
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

    if moderation &&
         Enum.member?(
           Podcast.ids_by_category_id(moderation.community.category_id),
           episode.podcast_id
         ) do
      {:ok, assign(socket, episode: episode, cols: cols, community: moderation.community)}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:saved, %{message: message}}, socket) do
    episode_grid_path =
      Routes.moderation_frontend_path(
        socket,
        :episode_grid,
        socket.assigns.community,
        socket.assigns.episode.podcast_id
      )

    {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: episode_grid_path)}
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      This episode/category combination is not within your moderations.
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={RecordForm}
      id={"record_form_episode_" <> Integer.to_string(@episode.id)}
      record={@episode}
      model={Episode}
      cols={@cols}
    />
    """
  end
end
