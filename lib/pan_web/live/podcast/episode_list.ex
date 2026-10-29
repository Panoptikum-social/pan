defmodule PanWeb.Live.Podcast.EpisodeList do
  use PanWeb, :html
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  alias PanWeb.Component.EpisodeButton
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.Icon

  attr :episodes, :any, required: false, default: []
  attr :page, :integer, required: false, default: 1
  attr :has_more, :boolean, required: false, default: true

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl">Episodes</h1>

    <table class="table table-sm table-zebra mt-4">
      <thead>
        <tr class="flex flex-col sm:table-row">
          <th>Date</th>
          <th>Title &amp; Description</th>
          <th>Contributors</th>
        </tr>
      </thead>
      <tbody id="table-body-episodes" phx-update="stream">
        <tr
          :for={{dom_id, episode} <- @episodes}
          id={dom_id}
          class="flex flex-col sm:table-row"
        >
          <td class="align-top whitespace-nowrap">
            {episode.publishing_date && Calendar.strftime(episode.publishing_date, "%x")}
          </td>
          <td class="align-top">
            <p><EpisodeButton.render for={episode} truncate /></p>
            {episode.description |> HtmlSanitizeEx.strip_tags() |> truncate_string(255)}
          </td>
          <td class="align-top leading-8">
            <%= for {persona, gigs} <- Enum.group_by(episode.gigs, &Map.get(&1, :persona)) do %>
              <nobr>
                <PersonaButton.render for={persona} />
                <%= for gig <- gigs do %>
                  <span class="badge badge-outline badge-secondary badge-sm" id={"gig-#{gig.id}"}>{gig.role}</span>
                  <span
                    :if={gig.self_proclaimed}
                    class="relative"
                    x-data="detailsToggle"
                  >
                    <div
                      class="inline"
                      @click="toggleDetails"
                    >
                      <Icon.render name="info-circle" />
                    </div>
                    <div
                      x-show="detailsOpen"
                      class="absolute right-0 mx-auto items-center bg-base-200 border border-base-300 p-4"
                    >
                      <h1 class="text-3xl">Info</h1>
                      <p class="mt-4">
                        This contribution is claimed by a user and not source of the podcast feed.
                      </p>
                      <p>
                        <button
                          @click="detailsOpen = false"
                          class="btn btn-outline btn-info btn-sm mt-4"
                          x-ref="detailsCloseButton"
                        >
                          Close
                        </button>
                      </p>
                    </div>
                  </span>
                  <br />
                <% end %>
              </nobr>
            <% end %>
          </td>
        </tr>
      </tbody>
    </table>
    <div :if={@has_more} id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}>
    </div>
    """
  end
end
