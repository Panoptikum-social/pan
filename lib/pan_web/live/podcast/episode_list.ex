defmodule PanWeb.Live.Podcast.EpisodeList do
  use Surface.Component
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Surface.Icon

  prop(episodes, :list, required: false, default: [])

  def render(assigns) do
    ~F"""
    <h2>Episodes</h2>

    <div class="table-responsive">
      <table class="table table-bordered table-condensed table-striped">
        <thead>
          <tr>
            <th>Date</th>
            <th>Title &amp; Description</th>
            <th>Contributors</th>
          </tr>
        </thead>
        <tbody>
          {#for episode <- @episodes}
            <tr>
              <td align="right">
                {#if episode.publishing_date}
                  {episode.publishing_date |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
                {/if}
              </td>
              <td id={"episode-#{episode.id}"}>
                <p style="line-height: 200%;">
                  <a href={episode_frontend_path(Endpoint, :show, episode)}
                     class="btn btn-primary btn-xs truncate"
                     id="detail-#{episode.id}">
                    <Icon name="headphones-lineawesome-solid"/> {episode.title || "no title"}</a>
                </p>
                {episode.description |> HtmlSanitizeEx.strip_tags |> truncate_string(255)}
              </td>
              <td style="line-height: 200%;">
                {#for {persona, gigs} <- Enum.group_by(episode.gigs, &Map.get(&1, :persona))}
                  <nobr>
                    <a href={persona_frontend_path(Endpoint, :show, persona)},
                       class="btn btn-xs btn-lavender" >
                       <Icon name="user-heroicons-outline"/> {persona.name}
                    </a>
                    {#for gig <- gigs}
                      <span class="label label-success" id={"gig-#{gig.id}"}>{gig.role}</span>
                      {#if gig.self_proclaimed}
                        <sup data-toggle="popover"
                             data-placement="right"
                             data-title="Claimed contribution"
                             data-html="true"
                             data-content="This contribution is claimed by a user and not source of
                                           the podcast feed.">
                          <Icon name="information-circle-heroicons"/>
                        </sup>
                      {/if}
                      <br/>
                    {/for}
                  </nobr>
                {/for}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    </div>
    """
  end
end
