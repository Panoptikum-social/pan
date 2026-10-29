defmodule PanWeb.Live.Podcast.Header do
  use PanWeb, :html
  alias PanWeb.Endpoint
  alias PanWeb.Component.Pill
  alias PanWeb.Component.QRCode
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.CategoryLink
  alias PanWeb.Component.Icon
  import PanWeb.Router.Helpers
  alias PanWeb.Live.Podcast.{ListFollowSubscribeButtons, PodloveSubscribeButton}

  attr :current_user_id, :integer, required: true
  attr :admin, :boolean, required: true
  attr :podcast, :map, required: true
  attr :episodes_count, :integer, required: true
  attr :podcast_thumbnail, :map, required: true
  attr :category_colors, :map, default: %{}

  def render(assigns) do
    ~H"""
    <div :if={@admin} class="fixed top-0 right-0 mt-4 mr-8 space-x-4">
      <a
        href={databrowser_path(Endpoint, :show, "podcast", @podcast)}
        class="underline hover:text-primary"
      >
        <Icon.render name="settings" /> Show Podcast
      </a>

      <a
        href={databrowser_path(Endpoint, :has_many, "feed", @podcast.feeds |> hd, "alternate_feeds")}
        class="underline hover:text-primary"
      >
        <Icon.render name="rss" /> Alternate Feeds
      </a>
    </div>

    <h1 class="text-3xl">{@podcast.title}</h1>

    <p
      :if={@podcast.retired}
      class="alert alert-soft alert-warning container max-w-3xl my-4"
      role="alert"
    >
      We retired this podcast, because we couldn't parse it for 10 consecutive times.
    </p>

    <div id="header" class="flex flex-col space-y-4 md:justify-between md:space-y-0 md:flex-row mt-4">
      <div class="flex flex-col space-y-4 lg:space-y-0 2xl:flex-row min-w-0">
        <div class="flex flex-col md:flex-row md:space-x-4 min-w-0 2xl:flex-1">
          <div class="flex-none p-2 2xl:mr-4 my-2 self-center lg:self-start">
            <div id="thumbnail" class="border border-base-300 shadow m-auto ">
              <img
                :if={Map.has_key?(@podcast_thumbnail, :path)}
                src={"https://panoptikum.social#{@podcast_thumbnail.path}#{@podcast_thumbnail.filename}"}
                width="150"
                height="150"
                alt={@podcast.image_title}
                id="photo"
                class="wrap-break-word text-xs"
              />
              <img
                :if={!Map.has_key?(@podcast_thumbnail, :path)}
                src="/images/missing-podcast.png"
                alt="missing image"
                width="150"
                height="150"
              />
            </div>
          </div>
          <div class="min-w-0">
            <p class="wrap-break-word">{@podcast.summary |> raw}</p>
          </div>
        </div>

        <dl class="grid grid-cols-[max-content_minmax(0,1fr)] gap-x-4 gap-y-2 min-w-0 2xl:w-md 2xl:flex-none [&>dd]:min-w-0 [&>dd]:wrap-break-word">
          <dt :if={@podcast.website} class="justify-self-end font-medium">Website</dt>
          <dd :if={@podcast.website}>
            <a
              href={@podcast.website}
              class="underline hover:text-primary"
            >{@podcast.website}</a>
          </dd>
          <dt :if={separate_description?(@podcast)} class="justify-self-end font-medium">
            Description
          </dt>
          <dd :if={separate_description?(@podcast)}>{@podcast.description}</dd>
          <dt :if={@podcast.payment_link_url} class="justify-self-end font-medium">Support</dt>
          <dd :if={@podcast.payment_link_url}>
            <a
              href={@podcast.payment_link_url |> String.trim()}
              class="underline hover:text-primary"
            >
              {@podcast.payment_link_title || "Support"}
            </a>
          </dd>
          <dt class="justify-self-end font-medium">Language</dt>
          <dd>
            <span :for={language <- @podcast.languages}>{language.emoji} {language.name}</span>
          </dd>
          <dt :if={@podcast.last_build_date} class="justify-self-end font-medium">last modified</dt>
          <dd :if={@podcast.last_build_date}>
            {Calendar.strftime(@podcast.last_build_date, "%x %H:%M")}
          </dd>
          <dt :if={@podcast.latest_episode_publishing_date} class="justify-self-end font-medium">
            last episode published
          </dt>
          <dd :if={@podcast.latest_episode_publishing_date}>
            {Calendar.strftime(@podcast.latest_episode_publishing_date, "%x %H:%M")}
          </dd>
          <dt
            :if={@podcast.publication_frequency && @podcast.publication_frequency > 0}
            class="justify-self-end font-medium"
          >
            publication frequency
          </dt>
          <dd :if={@podcast.publication_frequency && @podcast.publication_frequency > 0}>
            {@podcast.publication_frequency |> Float.round(2)} days
          </dd>

          <dt class="justify-self-end font-medium">Contributors</dt>
          <%= for {persona, engagements} <- Enum.group_by(@podcast.engagements, &Map.get(&1, :persona)) do %>
            <dd class="col-start-2 flex flex-wrap items-center gap-x-4 gap-y-1">
              <PersonaButton.render for={persona} />
              <span class="flex flex-wrap gap-1">
                <Pill.render :for={engagement <- engagements} type="lavender">
                  {engagement.role |> String.capitalize()}
                </Pill.render>
              </span>
            </dd>
          <% end %>
          <dt class="justify-self-end font-medium">Explicit</dt>
          <dd>{@podcast.explicit}</dd>
          <dt
            id="metadata"
            class="justify-self-end font-medium"
          >
            Number of Episodes
          </dt>
          <dd>{@episodes_count}</dd>
          <dt class="justify-self-end font-medium">
            <Icon.render name="rss" /> Rss-Feeds
          </dt>
          <dd>
            <a
              href={podcast_frontend_path(Endpoint, :feeds, @podcast)}
              class="underline hover:text-primary"
            >Detail page</a>
          </dd>
          <dt class="justify-self-end font-medium">Categories</dt>
          <dd class="leading-10">
            <CategoryLink.render
              :for={category <- @podcast.categories}
              for={category}
              color={@category_colors[category.id]}
              class="mr-3"
            />
          </dd>
        </dl>
      </div>

      <div role="qrcode" class="flex flex-col items-center gap-2">
        <QRCode.render for={podcast_frontend_url(Endpoint, :subscribe_button, @podcast)} />
        <.live_component
          module={PodloveSubscribeButton}
          id="podlove_subscribe_button"
          podcast={@podcast}
        />
      </div>
    </div>

    <.live_component
      module={ListFollowSubscribeButtons}
      id="list_follow_subscribe_button"
      current_user_id={@current_user_id}
      podcast={@podcast}
    />
    """
  end

  # many feeds repeat the summary as description, shown once next to the cover
  defp separate_description?(%{description: description, summary: summary})
       when is_binary(description),
       do: String.trim(description) not in ["", String.trim(summary || "")]

  defp separate_description?(_podcast), do: false
end
