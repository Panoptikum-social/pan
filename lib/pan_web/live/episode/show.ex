defmodule PanWeb.Live.Episode.Show do
  use Surface.LiveView
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Episode, Recommendation}
  alias PanWeb.Live.Episode.{Header, RecommendationList, ChapterList, PodlovePlayer}

  def mount(%{"id" => id}, _session, socket) do
    episode = Episode.get_by_id_for_episode_show(id)

    {:ok,
     assign(socket,
       episode: episode,
       changeset: %Recommendation{} |> Recommendation.changeset(),
       page_title: episode.title <> " (Episode) from " <> episode.podcast.title <> " (Podcast)"
     )}
  end

  defp major_mimetype(episode) do
    if mimetype(episode) do
      mimetype(episode)
      |> String.split("/")
      |> List.first()
    end
  end

  defp mimetype(episode) do
    if episode.enclosures != [] do
      episode.enclosures
      |> List.first()
      |> Map.get(:type)
    end
  end

  def render(assigns) do
    ~F"""
    <div class="m-4">
      {#if @episode.podcast.blocked}
        This episode may not be published here, sorry.
      {#else}
        <Header id="header"
                episode={@episode}
                current_user_id={@current_user_id} />
        <RecommendationList id="recommendation_list"
                            episode={@episode}
                            current_user_id={@current_user_id}
                            changeset={@changeset} />

        <div class="flex flex-col md:flex-row">
          {#if major_mimetype(@episode) == "video"}
            <video width="640" height="480" controls>
              {#for enclosure <- @episode.enclosures}
                <source src={enclosure.url}>
              {/for}
              Your browser does not support the video tag.
            </video>
          {#else}
            <PodlovePlayer id="player"
                           episode={@episode}
                           class="mr-4 lg:w-1/2" />
          {/if}

          <div id="shownotes" class="lg:w-1/2 mt-4 lg:mt-0">
            {#if @episode.shownotes}
              <h2 class="text-2xl">Shownotes</h2>
              <div class="my-2 prose max-w-none bg-white lg:p-2">{raw(@episode.shownotes)}</div>
            {/if}
          </div>
        </div>

        <ChapterList current_user_id={@current_user_id}
                     episode={@episode}
                     changeset={@changeset} />
      {/if}
    </div>
    """
  end
end
