defmodule PanWeb.Live.Moderation.EpisodeGrid do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Moderation, Podcast, Episode}
  alias PanWeb.Surface.Admin.Naming
  alias PanWeb.Surface.Moderation.ModerationGrid

  def mount(%{"id" => category_id, "podcast_id" => podcast_id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(category_id, session["user_id"])
    podcast = Podcast.get_by_id(podcast_id)

    columns = [
      :id, :title, :publishing_date, :guid, :duration, :full_text
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

    episode_ids = Episode.ids_by_category_id_and_podcast_id(category_id, podcast_id)
    podcast_ids = Podcast.ids_by_category_id(category_id)

    if moderation && Enum.member?(podcast_ids, String.to_integer(podcast_id)) do
      {:ok, assign(socket, podcast: podcast, cols: cols, episode_ids: episode_ids) }
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
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
        Podcast {@podcast.title} / Episodes
      </h1>

      <ModerationGrid id="episodes_table"
        heading={"Listing Episodes for Podcast #{@podcast.title}"}
        model={Episode}
        cols={@cols}
        search_filter={{:id, @episode_ids}}
        buttons={[:pagination, :number_of_records, :search]} />
    </div>
    """
  end
end
