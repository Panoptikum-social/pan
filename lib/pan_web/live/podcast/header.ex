defmodule PanWeb.Live.Podcast.Header do
  use PanWeb, :html
  alias PanWeb.Endpoint
  alias PanWeb.Component.Pill
  alias PanWeb.Component.QRCode
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.CategoryButton
  alias PanWeb.Component.Icon
  import PanWeb.Router.Helpers
  alias PanWeb.Live.Podcast.{ListFollowSubscribeButtons, PodloveSubscribeButton}

  attr :current_user_id, :integer, required: true
  attr :admin, :boolean, required: true
  attr :podcast, :map, required: true
  attr :episodes_count, :integer, required: true
  attr :podcast_thumbnail, :map, required: true

  def render(assigns) do
    ~H"""
    <div :if={@admin} class="fixed top-0 right-0 mt-4 mr-8 space-x-4">
      <a href={databrowser_path(Endpoint, :show, "podcast", @podcast)}
         class="text-link hover:text-link-dark">
        <Icon.render name="cog-heroicons-outline"/> Show Podcast
      </a>

      <a href={databrowser_path(Endpoint, :has_many, "feed", @podcast.feeds |> hd, "alternate_feeds")}
         class="text-link hover:text-link-dark">
        <Icon.render name="rss-heroicons-outline"/> Alternate Feeds
      </a>
    </div>

    <h1 class="text-3xl">{@podcast.title}</h1>

    <p :if={@podcast.retired}
        class="p-2 border border-warning-dark bg-warning-light/50 rounded-xl mb-4 container max-w-3xl my-4"
        role="alert">
      We retired this podcast, because we couldn't parse it for 10 consecutive times.
    </p>

    <div id="header" class="flex flex-col space-y-4 md:justify-between md:space-y-0 md:flex-row mt-4">
      <div class="flex flex-col space-y-4 lg:space-y-0 xl:flex-row">
        <div class="flex flex-col md:flex-row md:space-x-4">
          <div class="flex-none p-2 xl:mr-4 my-2 self-center lg:self-start">
            <div id="thumbnail" class="border border-gray-light shadow m-auto ">
              <img :if={Map.has_key?(@podcast_thumbnail, :path)}
                    src={"https://panoptikum.social#{@podcast_thumbnail.path}#{@podcast_thumbnail.filename}"}
                    width="150"
                    height="150"
                    alt={@podcast.image_title}
                    id="photo"
                    class="wrap-break-word text-xs" />
              <img :if={!Map.has_key?(@podcast_thumbnail, :path)}
                    src="/images/missing-podcast.png" alt="missing image" width="150" height="150" />
            </div>
          </div>
          <div>
            <p>{@podcast.summary |> raw}</p>
          </div>
        </div>

        <dl class="grid grid-cols-4 gap-x-4 gap-y-2">
          <dt :if={@podcast.website} class="justify-self-end font-medium">Website</dt>
          <dd :if={@podcast.website} class="col-span-3">
            <a href={@podcast.website}
                class="text-link hover:text-link-dark">{@podcast.website}</a>
          </dd>
          <dt class="justify-self-end font-medium">Description</dt>
          <dd class="col-span-3">{@podcast.description}</dd>
          <dt :if={@podcast.payment_link_url} class="justify-self-end font-medium">Support</dt>
          <dd :if={@podcast.payment_link_url} class="col-span-3">
            <a href={@podcast.payment_link_url |> String.trim}
                class="text-link hover:text-link-dark">
              {@podcast.payment_link_title || "Support"}
            </a>
          </dd>
          <dt class="justify-self-end font-medium">Language</dt>
          <dd class="col-span-3">
            <span :for={language <- @podcast.languages}>{language.emoji} {language.name}</span>
          </dd>
          <dt :if={@podcast.last_build_date} class="justify-self-end font-medium">last modified</dt>
          <dd :if={@podcast.last_build_date} class="col-span-3">{Calendar.strftime(@podcast.last_build_date, "%x %H:%M")}</dd>
          <dt :if={@podcast.latest_episode_publishing_date} class="justify-self-end font-medium">last episode published</dt>
          <dd :if={@podcast.latest_episode_publishing_date} class="col-span-3">{Calendar.strftime(@podcast.latest_episode_publishing_date, "%x %H:%M")}</dd>
          <dt :if={@podcast.publication_frequency && @podcast.publication_frequency > 0} class="justify-self-end font-medium">publication frequency</dt>
          <dd :if={@podcast.publication_frequency && @podcast.publication_frequency > 0} class="col-span-3">{@podcast.publication_frequency |> Float.round(2)} days</dd>

          <dt class="justify-self-end font-medium">Contributors</dt>
          <%= for {persona, engagements} <- Enum.group_by(@podcast.engagements, &Map.get(&1, :persona)) do %>
            <dd class="col-start-2 col-span-2">
              <PersonaButton.render for={persona}/>
            </dd>
            <dd class="col-start-4">
              <Pill.render :for={engagement <- engagements} type="lavender">{engagement.role |> String.capitalize}</Pill.render>
            </dd>
          <% end %>
          <dt class="justify-self-end font-medium">Explicit</dt>
          <dd class="col-span-3">{@podcast.explicit}</dd>
          <dt id="metadata"
              class="justify-self-end font-medium">Number of Episodes</dt>
          <dd class="col-span-3">{@episodes_count}</dd>
          <dt class="justify-self-end font-medium"><Icon.render name="rss-heroicons-outline"/> Rss-Feeds</dt>
          <dd class="col-span-3">
            <a href={podcast_frontend_path(Endpoint, :feeds, @podcast)}
                class="text-link hover:text-link-dark">Detail page</a></dd>
          <dt class="justify-self-end font-medium">Categories</dt>
          <dd class="col-span-3 leading-10">
            <CategoryButton.render :for={category <- @podcast.categories} for={category}/>
          </dd>
        </dl>
      </div>

      <div role="qrcode" class="flex flex-col items-end">
        <QRCode.render for={podcast_frontend_url(Endpoint, :subscribe_button, @podcast)} />
        <.live_component module={PodloveSubscribeButton}
                         id="podlove_subscribe_button"
                         podcast={@podcast} />
      </div>
    </div>

    <.live_component module={ListFollowSubscribeButtons}
                     id="list_follow_subscribe_button"
                     current_user_id={@current_user_id}
                     podcast={@podcast} />
    """
  end
end
