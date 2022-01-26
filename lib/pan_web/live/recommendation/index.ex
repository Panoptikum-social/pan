defmodule PanWeb.Live.Recommendation.Index do
  use Surface.LiveView
  alias PanWeb.Recommendation
  alias PanWeb.Surface.{Icon, UserButton, PodcastButton, EpisodeButton}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page: 1, per_page: 21)
     |> fetch(), temporary_assigns: [recommendations: []]}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page}} = socket) do
    assign(socket, latest_recommendations: Recommendation.latest(page, per_page))
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~F"""
    <div class="p-4">
      <h1 class="text-3xl">Latest Recommendations</h1>

      <div class="grid grid-cols-3"
           phx-update="append"">
        {#for recommendation <- @latest_recommendations}
          <div id={"recommendation-#{recommendation.id}"}
              class="m-2 p-2 rounded shadow">
            <div class="flex justify-between">
              <span><UserButton for={recommendation.user} /> recommended</span>
              <div>
                <Icon name="calendar-heroicons-outline" />
                {Calendar.strftime(recommendation.inserted_at, "%x")}
              </div>
            </div>

            <p class="leading-10 mb-4">
              <PodcastButton :if={recommendation.podcast}
                              for={recommendation.podcast} />

              {#if recommendation.episode}
                <PodcastButton for={recommendation.episode.podcast} /><br />
                <EpisodeButton for={recommendation.episode} />
              {/if}

              {#if recommendation.chapter_id}
                <PodcastButton for={recommendation.chapter.episode.podcast} /><br />
                <EpisodeButton for={recommendation.chapter.episode} /><br />
                <Icon name="indent-lineawesome-solid" /> {recommendation.chapter.title}
              {/if}
            </p>

            <p>
              <Icon name="thumb-up-heroicons-outline" />
              <i>„{recommendation.comment}“</i>
            </p>
          </div>
        {/for}
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </div>
    """
  end
end
