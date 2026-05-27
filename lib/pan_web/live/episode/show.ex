defmodule PanWeb.Live.Episode.Show do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{Episode, Recommendation}
  alias PanWeb.Live.Episode.{Header, RecommendationList, ChapterList, PodlovePlayer}

  def mount(%{"id" => id}, _session, socket) do
    case Episode.get_by_id_for_episode_show(id) do
      nil ->
        {:ok, socket |> put_flash(:error, "Episode not found.") |> redirect(to: "/")}

      episode ->
        {:ok,
         assign(socket,
           episode: episode,
           changeset: %Recommendation{} |> Recommendation.changeset(),
           page_title: (episode.title || "Episode") <> " from " <> (episode.podcast.title || "Podcast") <> " (Podcast)"
         )}
    end
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
    ~H"""
    <div class="m-4">
      <span :if={@episode.podcast.blocked}>
        This episode may not be published here, sorry.
      </span>
      <div :if={!@episode.podcast.blocked}>
        <.live_component module={Header}
                id="header"
                episode={@episode}
                current_user_id={@current_user_id} />
        <.live_component module={RecommendationList}
                            id="recommendation_list"
                            episode={@episode}
                            current_user_id={@current_user_id}
                            changeset={@changeset} />

        <div class="flex flex-col md:flex-row">
          <video :if={major_mimetype(@episode) == "video"} width="640" height="480" controls>
            <source :for={enclosure <- @episode.enclosures} src={enclosure.url}>
            Your browser does not support the video tag.
          </video>
          <.live_component :if={major_mimetype(@episode) != "video"}
                           module={PodlovePlayer}
                           id="player"
                           episode={@episode}
                           class="mr-4 lg:w-1/2" />

          <div id="shownotes" class="lg:w-1/2 mt-4 lg:mt-0">
            <div :if={@episode.shownotes}>
              <h2 class="text-2xl">Shownotes</h2>
              <div class="my-2 prose max-w-none bg-white lg:p-2">{raw(@episode.shownotes)}</div>
            </div>
          </div>
        </div>

        <ChapterList.render current_user_id={@current_user_id}
                     episode={@episode}
                     changeset={@changeset} />
      </div>
    </div>
    """
  end
end
