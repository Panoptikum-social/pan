defmodule PanWeb.Live.Podcast.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Recommendation, Podcast, Episode, Image}
  alias PanWeb.Live.Podcast.{Header, RecommendationList, EpisodeList}

  def mount(%{"id" => id}, _session, socket) do
    socket =
      assign(socket,
        podcast: Podcast.get_by_id_for_show(id),
        page: 1,
        per_page: 10,
        changeset: %Recommendation{} |> Recommendation.changeset,
        podcast_thumbnail: Image.get_by_podcast_id(id)
      )
      |> fetch

    {:ok, socket, temporary_assigns: [episodes: []]}
  end

  defp fetch(%{assigns: %{podcast: podcast, page: page, per_page: per_page}} = socket) do
    assign(socket, episodes: Episode.get_by_podcast_id(podcast.id, page, per_page))
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~F"""
    <div class="bg-white m-4 p-4 rounded shadow">
      {#if @podcast && @podcast.blocked == true}
        This podcast may not be published here, sorry.
      {#else}
        <Header current_user_id={@current_user_id}
                admin={@admin}
                podcast={@podcast}
                podcast_thumbnail={@podcast_thumbnail}
                episodes_count={@episodes |> length}/>
        <RecommendationList id="recommendations_list"
                            current_user_id={@current_user_id}
                            podcast={@podcast}
                            changeset={@changeset} />
        <EpisodeList episodes={@episodes}
                     page={@page} />
      {/if}
    </div>
    """
  end
end
