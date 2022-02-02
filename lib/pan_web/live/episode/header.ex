defmodule PanWeb.Live.Episode.Header do
  use Surface.LiveComponent
  alias PanWeb.{User, Episode}
  alias PanWeb.Surface.{PodcastButton, PersonaButton, EpisodeButton, Icon, LikeButton, Pill}
  alias PanWeb.Live.Episode.ClaimButton
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  prop(current_user_id, :integer, required: true)
  prop(episode, :map, required: true)
  data(current_user, :map)

  def update(%{current_user_id: current_user_id} = assigns, socket) do
    socket =
      if current_user_id do
        assign(socket, assigns)
        |> assign(current_user: User.get_by_id_with_personas(current_user_id))
      else
        assign(socket, assigns)
      end

    {:ok, socket}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

  defp truncated_filename(url) do
    url |> String.split("/") |> List.last() |> truncate_string(50)
  end

  def render(assigns) do
    ~F"""
    <div>
      <h1 class="leading-10">
        <PodcastButton for={@episode.podcast} large />
        &nbsp; / &nbsp;
        <EpisodeButton for={@episode} large class="my-2" />
      </h1>

      <div class="flex flex-col md:flex-row my-4 space-y-4 md:space-y-0 md:space-x-4 md:divide-x md:divide-dotted md:divide-gray">
        {#if (@episode.description && @episode.description != @episode.shownotes) ||
              (@episode.summary && @episode.summary != @episode.description)}
          <div class="flex-1">
            {#if @episode.description && @episode.description != @episode.shownotes}
              <h2 class="text-2xl">Description</h2>
              <p>{@episode.description |> HtmlSanitizeEx.strip_tags}</p>
            {/if}

            {#if @episode.summary && @episode.summary != @episode.description}
              <h3>Summary</h3>
              <p>{raw(@episode.summary)}</p>
            {/if}
          </div>
        {/if}

        <dl class="flex-1 grid grid-cols-4 gap-x-4 gap-y-2">
          <dt class="justify-self-end font-medium">Subtitle</dt>
          <dd class="col-span-3">{@episode.subtitle}</dd>
          {#if @episode.payment_link_url}
            <dt class="justify-self-end font-medium">Support</dt>
            <dd class="col-span-3"><a href={@episode.payment_link_url}>{@episode.payment_link_title}</a></dd>
          {/if}
          <dt class="justify-self-end font-medium">Duration</dt>
          <dd class="col-span-3">{@episode.duration}</dd>
          {#if @episode.publishing_date}
            <dt class="text-right font-medium">Publishing date</dt>
            <dd class="col-span-3">{Calendar.strftime(@episode.publishing_date, "%x %H:%M")}</dd>
          {/if}
          {#if @episode.link}
            <dt class="justify-self-end font-medium">Link</dt>
            <dd class="col-span-3">
              <a class="text-link hover:text-link-dark"
                 href={@episode.link}>{@episode.link}</a>
            </dd>
          {/if}
          {#if @episode.deep_link}
            <dt class="justify-self-end font-medium">Deep link</dt>
            <dd class="col-span-3">
              <a href={@episode.deep_link}
                 id="metadata"
                 class="text-link hover:text-link-dark">{@episode.deep_link}</a>
            </dd>
          {/if}
          <dt class="justify-self-end font-medium">Contributors</dt>
          {#for {persona, gigs} <- @episode.gigs |> Enum.group_by(&Map.get(&1, :persona))}
            <dd class="col-start-2 col-span-2">
              <PersonaButton for={persona}/>
            </dd>
            <dd dd class="col-start-4">
              {#for gig <- gigs}
                <Pill type="success"
                      id={"gig-#{gig.id}"}>{gig.role}</Pill>
                {#if gig.self_proclaimed}
                  <span class="relative"
                        x-data="{ metadataOpen: false }">
                    <div class="inline"
                         @click="metadataOpen = !metadataOpen
                                 $nextTick(() => $refs.metadataCloseButton.focus())">
                      <Icon name="information-circle-heroicons" />
                    </div>
                    <div x-show="metadataOpen"
                         class="absolute right-0 mx-auto items-center bg-gray-lightest border border-gray p-4 w-96 z-10">
                      <h1 class="text-2xl">Info</h1>
                      <p class="mt-4">
                        This contribution is claimed by a user and not source of the podcast feed.
                      </p>
                      <button @click="metadataOpen = false"
                              class="bg-info hover:bg-info-light text-white p-2 rounded mt-4
                                    focus:ring-2 focus:ring-info-light"
                              x-ref="metadataCloseButton">
                        Close
                      </button>
                    </div>
                  </span>
                {/if}
                &nbsp;
              {/for}
            </dd>
          {/for}

          <dt class="justify-self-end font-medium">Enclosures</dt>
          {#for enclosure <- @episode.enclosures}
          <dd class="col-start-2 col-span-2">
            <a class="text-link hover:text-link-dark break-words"
               href={enclosure.url |> String.trim }>{enclosure.url}</a>
            {#if is_integer(enclosure.length)}
              ({Float.round(String.to_integer(enclosure.length) / 1048576, 1)} MB)
            {/if}
          </dd>
          <dd class="col-start-4"><Pill type="info">{enclosure.type}</Pill></dd>
          {/for}
        </dl>
      </div>

      <div :if={@current_user_id} class="my-4">
        <h3 class="text-xl">Claim contribution</h3>
        <p class="mb-4 leading-10">
          {#for persona <- @current_user.personas}
            <ClaimButton id={"claim_persona_#{persona.id}_button"}
                         current_user_id={@current_user_id}
                         persona={persona}
                         episode_id={@episode.id}
                         caller={__MODULE__}
                         caller_id={@id} />
          {/for}
        </p>
      </div>


      <p :if={@current_user_id} class="my-4">
        <LikeButton id="like_episode_button"
                       current_user_id={@current_user_id}
                       model={Episode}
                       instance={@episode} />
      </p>
    </div>
    """
  end
end
