defmodule PanWeb.Live.Podcast.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin

  alias PanWeb.{Recommendation, Podcast, Episode, Image}
  alias PanWeb.Live.Podcast.{Header, RecommendationsList, EpisodeList}

  def mount(%{"id" => id}, _session, socket) do
    recommendation_changeset = Recommendation.changeset(%Recommendation{})

    podcast = Podcast.get_by_id_for_show(id)

    socket =
      assign(socket,
        podcast: podcast,
        episodes_page: 1,
        recommendations_page: 1,
        per_page: 10,
        recommendation_changeset: recommendation_changeset,
        podcast_thumbnail: Image.get_by_podcast_id(id)
      )
      |> fetch_episodes
      |> fetch_recommendations

    {:ok, socket, temporary_assigns: [recommendations: [], episodes: []]}
  end

  defp fetch_episodes(
         %{assigns: %{podcast: podcast, episodes_page: episodes_page, per_page: per_page}} =
           socket
       ) do
    assign(socket, episodes: Episode.get_by_podcast_id(podcast.id, episodes_page, per_page))
  end

  defp fetch_recommendations(
         %{
           assigns: %{
             podcast: podcast,
             recommendations_page: recommendations_page,
             per_page: per_page
           }
         } = socket
       ) do
    assign(socket,
      recommendations:
        Recommendation.get_by_podcast_id(podcast.id, recommendations_page, per_page)
    )
  end

  def handle_event("load-more-episodes", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch_episodes()}
  end

  def handle_event("load-more-recommendations", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch_recommendations()}
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
        <RecommendationsList current_user_id={@current_user_id}
                             podcast={@podcast}
                             changeset={@recommendation_changeset}
                             recommendations={@recommendations} />
        <EpisodeList episodes={@episodes} />
      {/if}
    </div>
    """
  end
end
