defmodule PanWeb.Live.Podcast.EpisodeList do
  use Surface.Component
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Surface.{Icon, PersonaButton, EpisodeButton}
  require Integer

  prop(episodes, :list, required: false, default: [])

  def render(assigns) do
    ~F"""
    <h2 class="text-2xl">Episodes</h2>

    <div class="table-responsive">
      <table class="border border-separate border-gray-lighter">
        <thead>
          <tr>
            <th>Date</th>
            <th>Title &amp; Description</th>
            <th>Contributors</th>
          </tr>
        </thead>
        <tbody>
          {#for {episode, index} <- @episodes |> Enum.with_index}
            <tr>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}
                  align="right">
                {#if episode.publishing_date}
                  {episode.publishing_date |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
                {/if}
              </td>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}
                  id={"episode-#{episode.id}"}>
                <EpisodeButton for={episode}/><br/>
                {episode.description |> HtmlSanitizeEx.strip_tags |> truncate_string(255)}
              </td>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}>
                {#for {persona, gigs} <- Enum.group_by(episode.gigs, &Map.get(&1, :persona))}
                  <nobr>
                    <PersonaButton for={persona}/>
                    {#for gig <- gigs}
                      <span class="bg-lavender-light rounded text-white p-1 text-sm" id={"gig-#{gig.id}"}>{gig.role}</span>
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
