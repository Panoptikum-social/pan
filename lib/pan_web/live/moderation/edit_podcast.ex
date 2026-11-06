defmodule PanWeb.Live.Moderation.EditPodcast do
  use PanWeb, :moderation_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast}
  alias PanWeb.Admin.Naming
  alias PanWeb.Component.Moderation.RecordForm
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => slug, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_community_slug_and_user_id(slug, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    # Deliberately not the full Podcast schema — a moderator-facing allowlist.
    # Excluded: :id/:episodes_count/:followers_count/:likes_count/
    # :subscriptions_count (primary key + derived counters), :unique_identifier/
    # :next_update/:next_podcast_update/:latest_episode_publishing_date/
    # :publication_frequency
    # (system-computed/derived), :manually_updated_at/:full_text/:thumbnailed/
    # :last_error_message/:last_error_occured (internal bookkeeping set by the
    # system, not a human), :inserted_at/:updated_at/:last_build_date
    # (Ecto-managed or feed-derived timestamps), and :blocked/:failure_count
    # (admin-only). :update_paused and :retired stay editable so a moderator
    # can resume/un-retire a podcast themselves after fixing a feed issue.
    columns = [
      title: dgettext("moderation", "Title"),
      website: dgettext("moderation", "Website"),
      description: dgettext("moderation", "Description"),
      summary: dgettext("moderation", "Summary"),
      image_title: dgettext("moderation", "Image title"),
      image_url: dgettext("moderation", "Image URL"),
      payment_link_title: dgettext("moderation", "Payment link title"),
      payment_link_url: dgettext("moderation", "Payment link URL"),
      explicit: dgettext("moderation", "Explicit"),
      update_paused: dgettext("moderation", "Update paused"),
      update_intervall: dgettext("moderation", "Update interval (hours)"),
      retired: dgettext("moderation", "Retired")
    ]

    cols =
      Enum.map(
        columns,
        fn {field, label} ->
          %{
            field: field,
            label: label,
            type: Naming.type_of_field(Podcast, field),
            searchable: true,
            sortable: true
          }
        end
      )

    if moderation &&
         Enum.member?(
           Podcast.ids_by_category_id(moderation.community.category_id),
           String.to_integer(podcast_id)
         ) do
      {:ok, assign(socket, podcast: podcast, cols: cols, community: moderation.community)}
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
      Routes.moderation_frontend_path(socket, :moderation, socket.assigns.community)

    {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: moderation_path)}
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      {dgettext("moderation", "This podcast/category combination is not within your moderations.")}
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={RecordForm}
      id={"record_form_podcast_" <> Integer.to_string(@podcast.id)}
      record={@podcast}
      model={Podcast}
      cols={@cols}
    />
    """
  end
end
