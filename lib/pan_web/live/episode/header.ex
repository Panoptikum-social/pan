defmodule PanWeb.Live.Episode.Header do
  use Surface.Component
  alias PanWeb.User
  alias PanWeb.Surface.{PodcastButton, PersonaButton, Pill, Icon}
  alias PanWeb.Live.Episode.{LikeButton, ClaimButton}

  prop(current_user_id, :integer, required: true)
  prop(episode, :map, required: true)
  data(current_user, :map)

  def render(assigns) do
    current_user = assigns.current_user_id && User.get_by_id_with_personas(assigns.current_user_id)
    assigns = assign(assigns, current_user: current_user)

    ~F"""
    <script>
      $(function() {
        $('[data-toggle="popover"]').popover()
      })
    </script>

    <h1>
      <PodcastButton for={@episode.podcast} large />
      &nbsp; / &nbsp;
      <Pill type="episode" large={true}><Icon name="headphones-lineawesome-solid" /> {@episode.title}</Pill>
    </h1>

    <div class="flex my-4 space-x-4 divide-x divide-dotted divide-gray">
      {#if (@episode.description && @episode.description != @episode.shownotes) ||
            (@episode.summary && @episode.summary != @episode.description)}
        <div class="flex-1">
          {#if @episode.description && @episode.description != @episode.shownotes}
            <h3 class="text-2xl">Description</h3>
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
          <dt class="justify-self-end font-medium">Publishing date</dt>
          <dd class="col-span-3">{Timex.format!(@episode.publishing_date, "{ISOdate} {h24}:{m}")}</dd>
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
                <sup data-toggle="popover"
                    data-placement="right"
                    data-title="Claimed contribution"
                    data-html="true"
                    data-content="This contribution is claimed by a user and not source of
                                  the podcast feed.">
                  <Icon name="information-circle-heroicons" class="icon-lavender" />
                </sup>
              {/if}
              &nbsp;
            {/for}
          </dd>
        {/for}

        <dt class="justify-self-end font-medium">Enclosures</dt>
        {#for enclosure <- @episode.enclosures}
        <dd class="col-start-2 col-span-2">
          <a class="text-link hover:text-link-dark"
            href={enclosure.url |> String.trim}>{String.split(enclosure.url, "/") |> List.last}</a>
          {#if is_integer(enclosure.length)}
            ({Float.round(String.to_integer(enclosure.length) / 1048576, 1)} MB)
          {/if}
        </dd>
        <dd class="col-start-4"><Pill type="info">{enclosure.type}</Pill></dd>
        {/for}
      </dl>
    </div>

    <div :if={@current_user_id} class="my-4">
      <h4 class="text-lg">Claim contribution</h4>
      <p class="mb-4 leading-10">
        {#for persona <- @current_user.personas}
          <ClaimButton id={"claim_persona_#{persona.id}_button"}
                       current_user_id={@current_user_id}
                       persona={persona}
                       episode_id={@episode.id}/>
        {/for}
      </p>
    </div>


    <p :if={@current_user_id} class="my-4">
      <LikeButton id="like_episode_button"
                     current_user_id={@current_user_id}
                     episode={@episode} />
    </p>
    <hr class="border-gray border-dotted"/>
  """
  end
end
