defmodule PanWeb.Live.Podcast.EpisodeList do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.Icon
  require Integer

  attr :episodes, :list, required: false, default: []
  attr :page, :integer, required: false, default: 1

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl">Episodes</h1>

    <table class="w-full table-fixed md:table-auto border border-separate border-gray-light mt-4">
      <thead>
        <tr class="flex flex-col sm:table-row">
          <th>Date</th>
          <th>Title &amp; Description</th>
          <th>Contributors</th>
        </tr>
      </thead>
      <tbody id="table-body-episodes" phx-update="append">
        <tr :for={episode <- @episodes}
            id={"episode-#{episode.id}"}
            class="flex flex-col sm:table-row even:bg-gray-lighter">
          <td class="p-2 text-center">
            {episode.publishing_date && Calendar.strftime(episode.publishing_date, "%x")}
          </td>
          <td class="p-2">
            <p><EpisodeButton.render for={episode} truncate/></p>
            {episode.description |> HtmlSanitizeEx.strip_tags |> truncate_string(255)}
          </td>
          <td class="p-2 leading-10">
            <%= for {persona, gigs} <- Enum.group_by(episode.gigs, &Map.get(&1, :persona)) do %>
              <nobr>
                <PersonaButton.render for={persona}/>
                <%= for gig <- gigs do %>
                  <span class="bg-lavender-light rounded text-white p-1 text-sm" id={"gig-#{gig.id}"}>{gig.role}</span>
                  <span :if={gig.self_proclaimed}
                        class="relative"
                        x-data="{ detailsOpen: false }">
                    <div class="inline"
                         @click="detailsOpen = !detailsOpen
                                 $nextTick(() => $refs.detailsCloseButton.focus())">
                      <Icon.render name="information-circle-heroicons" />
                    </div>
                    <div x-show="detailsOpen"
                          class="absolute right-0 mx-auto items-center bg-gray-lightest border border-gray p-4">
                      <h1 class="text-3xl">Info</h1>
                      <p class="mt-4">This contribution is claimed by a user and not source of the podcast feed.</p>
                      <p>
                        <button @click="detailsOpen = false"
                                class="bg-info hover:bg-info-light text-white px-2 rounded mt-4"
                                x-ref="detailsCloseButton">
                          Close
                        </button>
                      </p>
                    </div>
                  </span>
                  <br/>
                <% end %>
              </nobr>
            <% end %>
          </td>
        </tr>
      </tbody>
    </table>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
