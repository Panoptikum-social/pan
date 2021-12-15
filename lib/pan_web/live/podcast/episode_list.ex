defmodule PanWeb.Live.Podcast.EpisodeList do
  use Surface.Component
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Surface.{Icon, PersonaButton, EpisodeButton}
  require Integer

  prop(episodes, :list, required: false, default: [])
  prop(page, :integer, required: false, default: 1)

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
        <tbody id="table-body-episodes"
               phx-update="append">
          {#for {episode, index} <- @episodes |> Enum.with_index}
            <tr id={"episode-#{episode.id}"}>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}
                  align="right">
                {#if episode.publishing_date}
                  {episode.publishing_date |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
                {/if}
              </td>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}>
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
                        <span class="relative"
                              x-data="{ detailsOpen: false }">
                          <div class="inline"
                               @click="detailsOpen = !detailsOpen
                                       $nextTick(() => $refs.detailsCloseButton.focus())">
                            <Icon name="information-circle-heroicons" />
                          </div>
                          <div x-show="detailsOpen"
                                class="absolute right-0 mx-auto items-center bg-gray-lightest border border-gray p-4">
                            <h1 class="text-2xl">Info</h1>
                            <p class="mt-4">This contribution is claimed by a user and not source of the podcast feed.</p>
                            <button @click="detailsOpen = false"
                                    class="bg-info hover:bg-info-light text-white p-2 rounded mt-4
                                            focus:ring-2 focus:ring-info-light"
                                    x-ref="detailsCloseButton">
                              Close
                            </button>
                          </div>
                        </span>
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
      <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    </div>
    """
  end
end
