defmodule PanWeb.Live.Podcast.Header do
  use Surface.Component
  alias PanWeb.Endpoint
  alias PanWeb.Surface.{Icon, CategoryButton, PersonaButton, Pill}
  import PanWeb.Router.Helpers
  alias PanWeb.Live.Podcast.{ListFollowSubscribeButtons, SubscribeButton}

  prop(current_user_id, :integer, required: true)
  prop(admin, :boolean, required: true)
  prop(podcast, :map, required: true)
  prop(episodes_count, :integer, required: true)
  prop(podcast_thumbnail, :map, required: true)

  def render(assigns) do
    ~F"""
    {#if @admin}
      <div class="fixed top-0 right-0 mt-4 mr-8">
        <a href={databrowser_path(Endpoint, :show, "podcast", @podcast)}>
          <Icon name="cog-heroicons-outline"/>
        </a>

        <a href={databrowser_path(Endpoint, :edit, "feed", @podcast.feeds |> hd)}>
          <Icon name="rss-heroicons-outline"/>
        </a>
      </div>
    {/if}

    <h1 class="text-3xl">{@podcast.title}</h1>

    <p :if={@podcast.retired}
        class="alert alert-warning container"
        role="alert">
      We retired this podcast, because we couldn't parse it for 10 consecutive times.
    </p>

    <div class="flex flex-row mt-4">
      <div class="flex flex-row">
        <div>
          <div class="flex flex-row">
            <div class="flex-none p-2 mr-4 my-2 border border-gray-light shadow">
              {#if @podcast_thumbnail}
                <a href={"https://panoptikum.io#{@podcast_thumbnail.path}#{@podcast_thumbnail.filename}"}
                   width="150" height="150" alt="@podcast.image_title" id="photo" />
              {#else}
                <img src="/images/missing-podcast.png" alt="missing image" width="150" height="150" />
              {/if}
            </div>
            <div>
              <p>{@podcast.summary |> raw}</p>
            </div>
          </div>
          <p class="mt-4">
            <ListFollowSubscribeButtons current_user_id={@current_user_id}
                                        podcast={@podcast} />
          </p>
        </div>

        <div class="border-l border-r border-dotted border-gray-light">
          <dl class="grid grid-cols-4 gap-4">
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
              <dd class="col-span-3">{@podcast.last_build_date |> Timex.format!("{ISOdate} {h24}:{m}")}</dd>
            {/if}
            {#if @podcast.latest_episode_publishing_date}
              <dt class="justify-self-end font-medium">last episode published</dt>
              <dd class="col-span-3">{@podcast.latest_episode_publishing_date |> Timex.format!("{ISOdate} {h24}:{m}")}</dd>
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
            <dd class="col-span-3" style="line-height: 200%;">
              {#for category <- @podcast.categories}
                <CategoryButton for={category}/>
              {/for}
            </dd>
          </dl>
        </div>

      </div>

      <div role="qrcode" class="flex flex-col">
        <img src={"/qrcode/#{podcast_frontend_url(Endpoint, :subscribe_button, @podcast) |> URI.encode_www_form}"}
                    class="max-w-none" width="150" height="150" %>
        <SubscribeButton :if={@current_user_id}
                         id="qr_code_subscribe_button"
                         current_user_id={@current_user_id}
                         podcast={@podcast} />
      </div>
    </div>

    """
  end
end
