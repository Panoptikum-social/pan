defmodule PanWeb.Live.Moderation.Moderate do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast}
  alias PanWeb.Surface.Admin.{IndexGrid, Naming}

  def mount(%{"id" => id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(id, session["user_id"])

    columns = [
      :id, :title, :last_build_date, :blocked, :update_paused, :retired, :failure_count,
      :episodes_count, :latest_episode_publishing_date, :publication_frequency,
      :manually_updated_at, :full_text, :last_error_message, :last_error_occured]

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

    podcast_ids = Podcast.ids_by_category_id(id)

    if moderation do
      {:ok, assign(socket, category: moderation.category, cols: cols, podcast_ids: podcast_ids) }
    else
      {:ok, assign(socket, error: "This is not one of your moderations")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      <h1 class="text-2xl">
        Moderating {@category.title}
      </h1>

      <IndexGrid id="moderation_table"
        heading="Listing Podcasts"
        model={Podcast}
        cols={@cols}
        search_filter={{:id, @podcast_ids}}
        buttons={[:pagination, :number_of_records, :search]} />
    </div>
    """
  end
end
