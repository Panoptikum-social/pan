defmodule PanWeb.Live.Moderation.EditEpisode do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, "live_admin.html"},
    container: {:div, class: "flex-1 w-full"}

  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast, Episode}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => category_id, "episode_id" => episode_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    episode = Episode.get_by_id(episode_id)

    columns = [
      :id,
      :podcast_id,
      :title,
      :link,
      :publishing_date,
      :guid,
      :description,
      :shownotes,
      :payment_link_title,
      :payment_link_url,
      :deep_link,
      :duration,
      :subtitle,
      :summary,
      :image_title,
      :image_url,
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

    podcast_ids = Podcast.ids_by_category_id(category_id)

    if moderation && Enum.member?(podcast_ids, episode.podcast_id) do
      {:ok, assign(socket, episode: episode, cols: cols, category_id: category_id)}
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
        socket.assigns.category_id,
        socket.assigns.episode.podcast_id
      )

    {:noreply, socket |> put_flash(:info, message) |> push_redirect(to: episode_grid_path)}
  end

  def render(%{error: "not_found"} = assigns) do
    ~F"""
    <div class="m-12">
      This episode/category combination is not within your moderations.
    </div>
    """
  end

  def render(assigns) do
    ~F"""
    <RecordForm id={"record_form_episode_" <> Integer.to_string(@episode.id)}
    record={@episode}
    model={Episode}
    {=@cols} />
    """
  end
end
