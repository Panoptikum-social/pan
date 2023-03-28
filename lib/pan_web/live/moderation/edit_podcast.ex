defmodule PanWeb.Live.Moderation.EditPodcast do
  use Surface.LiveView,
    layout: {PanWeb.LayoutView, :live_admin},
    container: {:div, class: "flex-1 w-full"}

  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => category_id, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    columns = [
      :id,
      :title,
      :website,
      :description,
      :summary,
      :image_title,
      :image_url,
      :last_build_date,
      :payment_link_title,
      :payment_link_url,
      :explicit,
      :blocked,
      :update_paused,
      :update_intervall,
      :next_update,
      :retired,
      :failure_count,
      :unique_identifier,
      :episodes_count,
      :followers_count,
      :likes_count,
      :subscriptions_count,
      :latest_episode_publishing_date,
      :publication_frequency,
      :manually_updated_at,
      :full_text,
      :thumbnailed,
      :last_error_message,
      :last_error_occured,
      :inserted_at,
      :updated_at
    ]

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(Podcast, &1),
          searchable: true,
          sortable: true
        }
      )

    podcast_ids = Podcast.ids_by_category_id(category_id)

    if moderation && Enum.member?(podcast_ids, String.to_integer(podcast_id)) do
      {:ok, assign(socket, podcast: podcast, cols: cols, category_id: category_id)}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:saved, %{message: message}}, socket) do
    moderation_path =
      Routes.moderation_frontend_path(socket, :moderation, socket.assigns.category_id)

    {:noreply, socket |> put_flash(:info, message) |> push_redirect(to: moderation_path)}
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
    <RecordForm id={"record_form_podcast_" <> Integer.to_string(@podcast.id)}
      record = {@podcast}
      model= {Podcast}
      {=@cols} />
    """
  end
end
