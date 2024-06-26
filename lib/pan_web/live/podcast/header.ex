defmodule PanWeb.Live.Podcast.Header do
  use Surface.Component
  alias PanWeb.Endpoint
  alias PanWeb.Surface.{Icon, CategoryButton, PersonaButton, Pill, QRCode}
  import PanWeb.Router.Helpers
  alias PanWeb.Live.Podcast.{ListFollowSubscribeButtons, PodloveSubscribeButton}

  prop(current_user_id, :integer, required: true)
  prop(admin, :boolean, required: true)
  prop(podcast, :map, required: true)
  prop(episodes_count, :integer, required: true)
  prop(podcast_thumbnail, :map, required: true)

  def render(assigns) do
    ~F"""
    {#if @admin}
      <div class="fixed top-0 right-0 mt-4 mr-8 space-x-4">
        <a href={databrowser_path(Endpoint, :show, "podcast", @podcast)}
           class="text-link hover:text-link-dark">
          <Icon name="cog-heroicons-outline"/> Show Podcast
        </a>

        <a href={databrowser_path(Endpoint, :has_many, "feed", @podcast.feeds |> hd, "alternate_feeds")},
           class="text-link hover:text-link-dark">
          <Icon name="rss-heroicons-outline"/> Alternate Feeds
        </a>
      </div>
    {/if}

    <h1 class="text-3xl">{@podcast.title}</h1>

    <p :if={@podcast.retired}
        class="p-2 border border-warning-dark bg-warning-light/50 rounded-xl mb-4 container max-w-screen-md my-4"
        role="alert">
      We retired this podcast, because we couldn't parse it for 10 consecutive times.
    </p>

    <div id="header" class="flex flex-col space-y-4 md:justify-between md:space-y-0 md:flex-row mt-4">
      <div class="flex flex-col space-y-4 lg:space-y-0 xl:flex-row">
        <div class="flex flex-col md:flex-row md:space-x-4">
          <div class="flex-none p-2 xl:mr-4 my-2 self-center lg:self-start">
            <div id="thumbnail" class="border border-gray-light shadow m-auto ">
              {#if Map.has_key?(@podcast_thumbnail, :path)}
                <img src={"https://panoptikum.social#{@podcast_thumbnail.path}#{@podcast_thumbnail.filename}"}
                      width="150"
                      height="150"
                      alt={@podcast.image_title}
                      id="photo"
                      class="break-words text-xs" />
              {#else}
                <img src="/images/missing-podcast.png" alt="missing image" width="150" height="150" />
              {/if}
            </div>
          </div>
          <div>
            <p>{@podcast.summary |> raw}</p>
          </div>
        </div>

        <dl class="grid grid-cols-4 gap-x-4 gap-y-2">
          {#if @podcast.website}
            <dt class="justify-self-end font-medium">Website</dt>
            <dd class="col-span-3">
              <a href={String.downcase(@podcast.website)}
                  class="text-link hover:text-link-dark">{@podcast.website}</a>
            </dd>
          {/if}
          <dt class="justify-self-end font-medium">Description</dt>
          <dd class="col-span-3">{@podcast.description}</dd>
          {#if @podcast.payment_link_url}
            <dt class="justify-self-end font-medium">Support</dt>
            <dd class="col-span-3">
              <a href={@podcast.payment_link_url |> String.trim}
                  class="text-link hover:text-link-dark">
                {@podcast.payment_link_title || "Support"}
              </a>
            </dd>
          {/if}
          <dt class="justify-self-end font-medium">Language</dt>
          <dd class="col-span-3">
            {#for language <- @podcast.languages}
              {language.emoji} {language.name}
            {/for}
          </dd>
          {#if @podcast.last_build_date}
            <dt class="justify-self-end font-medium">last modified</dt>
            <dd class="col-span-3">{Calendar.strftime(@podcast.last_build_date, "%x %H:%M")}</dd>
          {/if}
          {#if @podcast.latest_episode_publishing_date}
            <dt class="justify-self-end font-medium">last episode published</dt>
            <dd class="col-span-3">{Calendar.strftime(@podcast.latest_episode_publishing_date, "%x %H:%M")}</dd>
          {/if}
          {#if @podcast.publication_frequency > 0}
            <dt class="justify-self-end font-medium">publication frequency</dt>
            <dd class="col-span-3">{@podcast.publication_frequency |> Float.round(2)} days</dd>
          {/if}

          <dt class="justify-self-end font-medium">Contributors</dt>
          {#for {persona, engagements} <- Enum.group_by(@podcast.engagements, &Map.get(&1, :persona))}
            <dd class="col-start-2 col-span-2">
              <PersonaButton for={persona}/>
            </dd>
            <dd class="col-start-4">
              {#for engagement <- engagements}
                <Pill type="lavender">{engagement.role |> String.capitalize}</Pill>
              {/for}
            </dd>
          {/for}
          <dt class="justify-self-end font-medium">Explicit</dt>
          <dd class="col-span-3">{@podcast.explicit}</dd>
          <dt id="metadata"
              class="justify-self-end font-medium">Number of Episodes</dt>
          <dd class="col-span-3">{@episodes_count}</dd>
          <dt class="justify-self-end font-medium"><Icon name="rss-heroicons-outline"/> Rss-Feeds</dt>
          <dd class="col-span-3">
            <a href={podcast_frontend_path(Endpoint, :feeds, @podcast)}
                class="text-link hover:text-link-dark">Detail page</a></dd>
          <dt class="justify-self-end font-medium">Categories</dt>
          <dd class="col-span-3 leading-10">
            {#for category <- @podcast.categories}
              <CategoryButton for={category}/>
            {/for}
          </dd>
        </dl>
      </div>

      <div role="qrcode" class="flex flex-col items-end">
        <QRCode for={podcast_frontend_url(Endpoint, :subscribe_button, @podcast)} />
        <PodloveSubscribeButton id="podlove_subscribe_button"
                                {=@podcast} />
      </div>
    </div>

    <ListFollowSubscribeButtons id="list_follow_subscribe_button"
                                current_user_id={@current_user_id}
                                podcast={@podcast} />
    """
  end
end
