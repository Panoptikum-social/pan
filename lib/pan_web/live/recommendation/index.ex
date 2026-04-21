defmodule PanWeb.Live.Recommendation.Index do
  use PanWeb, :live_view
  alias PanWeb.Recommendation
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PodcastButton
  alias PanWeb.Component.UserButton
  alias PanWeb.Component.Icon

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, page: 1, per_page: 21, page_title: "Latest Recommendations")
     |> fetch(), temporary_assigns: [recommendations: []]}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page}} = socket) do
    assign(socket, latest_recommendations: Recommendation.latest(page, per_page))
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h1 class="text-3xl">Latest Recommendations</h1>

      <div id="recommendations-grid"
           class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3"
           phx-update="append">
        <div :for={recommendation <- @latest_recommendations}
             id={"recommendation-#{recommendation.id}"}
             class="m-2 p-2 rounded shadow">
          <div class="flex justify-between">
            <span><UserButton.render for={recommendation.user} /> recommended</span>
            <div>
              <Icon.render name="calendar-heroicons-outline" />
              {Calendar.strftime(recommendation.inserted_at, "%x")}
            </div>
          </div>

          <p class="leading-10 mb-4">
            <PodcastButton.render :if={recommendation.podcast}
                            for={recommendation.podcast} />

            <span :if={recommendation.episode}>
              <PodcastButton.render for={recommendation.episode.podcast} /><br />
              <EpisodeButton.render for={recommendation.episode} />
            </span>

            <span :if={recommendation.chapter_id}>
              <PodcastButton.render for={recommendation.chapter.episode.podcast} /><br />
              <EpisodeButton.render for={recommendation.chapter.episode} /><br />
              <Icon.render name="indent-lineawesome-solid" /> {recommendation.chapter.title}
            </span>
          </p>

          <p>
            <Icon.render name="thumb-up-heroicons-outline" />
            <i>„{recommendation.comment}"</i>
          </p>
        </div>
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </div>
    """
  end
end
