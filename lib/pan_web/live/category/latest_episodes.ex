defmodule PanWeb.Live.Category.LatestEpisodes do
  use Surface.LiveView
  alias PanWeb.{Category, Podcast, Episode}
  alias PanWeb.Surface.{EpisodeCard, PodcastButton, Panel}

  def mount(%{"id" => id}, _session, socket) do
    podcast_ids = Podcast.ids_by_category_id(id)

    socket =
      assign(socket,
        page: 1,
        per_page: 15,
        category: Category.get_by_id_with_parent(id),
        podcast_ids: podcast_ids
      )

    {:ok, socket |> fetch(), temporary_assigns: [latest_episodes: []]}
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
      <div id="latest_episodes" phx-update="append" class="m-2 grid md:grid-cols-2 2xl:grid-cols-3 gap-4">
        {#for episode <- @latest_episodes }
          <div id={"episode-#{episode.id}"} class="p-2 rounded-xl shadow">
            <p class="mb-1">Podcast <PodcastButton id={episode.podcast_id} title={episode.podcast_title} /></p>
            <EpisodeCard for={episode}/>
          </div>
        {/for}
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </Panel>
    """
  end
end
