defmodule PanWeb.Live.Episode.Header do
  use Surface.Component
  alias PanWeb.User
  alias PanWeb.Surface.{PodcastButton, PersonaButton, Pill, Icon}
  alias PanWeb.Live.Episode.{LikeButton, ClaimButton}

  prop(current_user_id, :integer, required: true)
  prop(episode, :map, required: true)
  data(current_user, :map)

  def render(assigns) do
    assign(assigns, user: assigns.current_user_id && User.get_by_id_with_personas(assigns.current_user_id))

    ~F"""
    <script>
      $(function() {
        $('[data-toggle="popover"]').popover()
      })
    </script>

    <h1 style="line-height: 200%;">
      <PodcastButton for={@episode.podcast} />
      &nbsp; / &nbsp;
      <Pill type="episode"><Icon name="headphones-lineawesome-solid" /> {@episode.title}</Pill>
    </h1>

    <div class="row">
      {#if (@episode.description && @episode.description != @episode.shownotes) ||
            (@episode.summary && @episode.summary != @episode.description)}
        <div class={"col-md-5": @episode.image_url,
                    "col-md-7": !@episode.image_url}
             style="border-right: 1px dotted #ccc;">
          {#if @episode.description && @episode.description != @episode.shownotes}
            <h3>Description</h3>
            <p>{@episode.description |> HtmlSanitizeEx.strip_tags}</p>
          {/if}

          {#if @episode.summary && @episode.summary != @episode.description}
            <h3>Summary</h3>
            <p>{raw(@episode.summary)}</p>
          {/if}
        </div>
      {/if}

      <div class="col-md-5">
        <dl class="dl-horizontal" style="margin-top: 30px;">
          <dt>Subtitle</dt>
          <dd>{@episode.subtitle}</dd>
          {#if @episode.payment_link_url}
            <dt>Support</dt>
            <dd><a href={@episode.payment_link_url}>{@episode.payment_link_title}</a></dd>
          {/if}
          <dt>Duration</dt>
          <dd>{@episode.duration}</dd>
          {#if @episode.publishing_date}
            <dt>Publishing date</dt>
            <dd>{Timex.format!(@episode.publishing_date, "{ISOdate} {h24}:{m}")}</dd>
          {/if}
          {#if @episode.link}
            <dt>Link</dt>
            <dd><a href={@episode.link}>{@episode.link}</a></dd>
          {/if}
          {#if @episode.deep_link}
            <dt>Deep link</dt>
            <dd><a href={@episode.deep_link} id="metadata">{@episode.deep_link}</a></dd>
          {/if}
          <dt>Contributors</dt>
          {#for {persona, gigs} <- @episode.gigs |> Enum.group_by(&Map.get(&1, :persona))}
            <dd style="line-height: 200%;">
              <PersonaButton for={persona}/>
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

          <dt>Enclosures</dt>
          <dd></dd>
          {#for enclosure <- @episode.enclosures}
            <dt><Pill type="primary">{enclosure.type}</Pill></dt>
            <dd>
              <a href={enclosure.url |> String.trim}>{String.split(enclosure.url, "/") |> List.last}</a>

              {#if is_integer(enclosure.length)}
                ({Float.round(String.to_integer(enclosure.length) / 1048576, 1)} MB)
              {/if}
            </dd>
          {/for}
        </dl>
      </div>
    </div>

    {#if @current_user_id}
      <br/>
      <b>Claim contribution</b>
      <p class="leading-10">
        {#for persona <- @current_user.personas}
          <ClaimButton id={"claim_persona_#{persona.id}_button"}
                       current_user_id={@current_user_id}
                       persona={persona}
                       episode_id={@episode.id}/>
        {/for}
      </p>
    {/if}


    <p :if={@current_user_id}>
      <LikeButton id="like_episode_button"
                     current_user_id={@current_user_id}
                     episode={@episode} />
    </p>
    <hr/>
  """
  end
end
