defmodule PanWeb.Live.Category.LatestEpisodes do
  use Surface.LiveView
  alias PanWeb.{Category, Podcast, Episode}
  alias PanWeb.Surface.{EpisodeCard, PodcastButton, Panel}

  def mount(%{"id" => id}, _session, socket) do
    podcast_ids = Podcast.ids_by_category_id(id)

    {:ok,
     socket
     |> assign(
       page: 1,
       per_page: 10,
       category: Category.get_by_id_with_parent(id),
       podcast_ids: podcast_ids
     )
     |> fetch(), temporary_assigns: [latest_episodes: []]}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, podcast_ids: podcast_ids}} = socket) do
    latest_episodes = Episode.latest_episodes_by_podcast_ids(podcast_ids, page, per_page)
    assign(socket, latest_episodes: latest_episodes)
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~F"""
    <Panel heading={"Latest Episodes for #{@category.title}"} purpose="episode" class="m-4">
      <div id="latest_episodes" phx-update="append" class="m-4">
        {#for episode <- @latest_episodes }
          <div id={"episode-#{episode.id}"} class="mt-4 p-4 rounded-xl shadow">
            <EpisodeCard for={episode}/>
            <PodcastButton id={episode.podcast_id} title={episode.podcast_title} />
          </div>
        {/for}
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </Panel>
    """
  end
end
