defmodule PanWeb.Live.Home do
  use PanWeb, :live_view
  alias PanWeb.Component.Panel
  alias PanWeb.Component.EpisodeCard
  alias PanWeb.Component.TopList
  alias PanWeb.Component.PodcastCard
  alias PanWeb.Component.RecommendationCard
  alias PanWeb.{Podcast, Episode, Recommendation, Endpoint}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       popular_podcasts: Podcast.popular(),
       liked_podcasts: Podcast.liked(),
       latest_podcast: Podcast.latest(),
       latest_episode: Episode.latest(),
       latest_recommendation: Recommendation.latest(),
       page_title: "The Podcast Panoptikum "
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 justify-self-center m-2">
      <div x-data="{ cookie_consent: true }"
           x-init="() => {cookie_consent = localStorage.getItem('cookie_consent')}"
           class="text-center mb-2">
        <div x-show="cookie_consent != 'true'" x-cloak>
          Panoptikum.social uses cookies only out of technical necessity. See our
          <.link href="https://blog.panoptikum.social/privacy"
                class="text-link hover:text-link-dark"> Privacy Page</.link>
          for details.
          <button @click.prevent="cookie_consent = 'true'; localStorage.setItem('cookie_consent', 'true')"
             class="inline border border-gray text-sm rounded p-1 bg-white hover:bg-gray-lightest">
            I agree
          </button>
        </div>
      </div>

      <div class="max-w-7xl mx-auto
                  flex flex-col space-y-4 justify-items-auto
                  lg:flex-row lg:space-y-0 lg:space-x-4">
        <div aria-label="left column" class="flex-1">
          <Panel.render heading="Top 10 most liked Podcasts"
                        heading_right="more ..."
                        target={podcast_frontend_path(Endpoint, :liked)}
                        purpose="like">
            <TopList.render items={@liked_podcasts}
                            purpose="podcast"
                            icon="heart-heroicons-outline" />
          </Panel.render>

          <Panel.render heading="Top 10 subscribed Podcasts" heading_right="more ..."
                        target={podcast_frontend_path(Endpoint, :popular)}
                        purpose="popular"
                        class="mt-4">
            <TopList.render items={@popular_podcasts}
                            purpose="podcast"
                            icon="user-heroicons-outline" />
          </Panel.render>
        </div>

        <div class="flex-1">
          <Panel.render heading="Latest Podcast" heading_right="more ..."
                        target={podcast_frontend_path(Endpoint, :index)}
                        purpose="podcast"
                        content_class="p-4">
            <PodcastCard.render for={@latest_podcast} />
            <p class="mt-4">
              <a href={podcast_frontend_path(Endpoint, :index)}
                 class="text-link hover:text-link-dark">show more...</a>
            </p>
          </Panel.render>

          <Panel.render heading="Latest Episode"
                        heading_right="more ..."
                        target={episode_frontend_path(Endpoint, :index)}
                        purpose="episode"
                        content_class="p-4"
                        class="mt-4">
            <EpisodeCard.render for={@latest_episode} />
            <p class="mt-4">
              <a href={episode_frontend_path(Endpoint, :index)}
                 class="text-link hover:text-link-dark">show more...</a>
            </p>
          </Panel.render>

          <Panel.render heading="Latest Recommendation"
                        heading_right="more ..."
                        target={recommendation_frontend_path(Endpoint, :index)}
                        purpose="recommendation"
                        class="mt-4"
                        content_class="p-4">
            <RecommendationCard.render for={@latest_recommendation} />
            <p class="mt-4">
              <a href={recommendation_frontend_path(Endpoint, :index)}
                 class="text-link hover:text-link-dark">show more...</a>
            </p>
          </Panel.render>
        </div>
      </div>
    </div>
    """
  end
end
