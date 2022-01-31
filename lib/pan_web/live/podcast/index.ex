defmodule PanWeb.Live.Podcast.Index do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  alias PanWeb.{Podcast, Endpoint}
  alias PanWeb.Surface.{Panel, CategoryButton, PersonaButton, Icon}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, page: 1, per_page: 15, page_title: "Latest Podcasts")
     |> fetch(), temporary_assigns: [latest_episodes: []]}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page}} = socket) do
    latest_podcasts = Podcast.latest_for_index(page, per_page)
    assign(socket, latest_podcasts: latest_podcasts)
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~F"""
    <Panel heading="Latest Podcasts" purpose="podcasts" class="m-4">
      <div id="latest_podcasts" phx-update="append" class="m-2 grid md:grid-cols-2 2xl:grid-cols-3 gap-4">
        {#for podcast <- @latest_podcasts }
          <Panel purpose="podcast"
                 id={"podcast-#{podcast.id}"}
                 heading={podcast.title}
                 target={podcast_frontend_path(Endpoint, :show, podcast.id)}>
            <div class="flex items-start space-x-2">
              <div class="w-40 h-40 flex-none">
                <img :if={podcast.thumbnails != []}
                      src={"https://panoptikum.io#{podcast.thumbnails |> List.first |> Map.get(:path)}"}
                      alt={podcast.image_title}
                      type="image/png"
                      class="object-contain ring-4 ring-gray rounded-xl" />
              </div>
              <table>
                <tr :if={podcast.website}>
                  <td>
                    <label class="text-xs py-1 px-1.5 text-white rounded bg-danger m-1">
                      Website
                    </label>
                  </td>
                  <td><a href={podcast.website}>{podcast.website}</a></td>
                </tr>

                <tr>
                  <td>
                    <nobr>
                      <label class="text-xs py-1 px-1.5 text-white rounded bg-info m-1">
                        Available since
                      </label>
                    </nobr>
                  </td>
                  <td>
                    <Icon name="calendar-heroicons-outline"/>
                    {Calendar.strftime(podcast.inserted_at, "%x")}
                  </td>
                </tr>

                <tr>
                  <td>
                    <label class="text-xs py-1 px-1.5 text-white rounded bg-warning m-1">
                      Categories
                    </label>
                  </td>
                  <td style="line-height: 200%;">
                    {#for category <- podcast.categories}
                      <CategoryButton for={category}/>
                    {/for}
                  </td>
                </tr>

                <tr>
                  <td>
                    <label class="text-xs py-1 px-1.5 text-white rounded bg-aqua m-1">
                      Contributors
                    </label>
                  </td>
                  <td class="leading-9">
                    {#for engagement <- podcast.engagements}
                      <PersonaButton for={engagement.persona} />
                      <span class="text-xs py-1 px-1.5 text-white rounded bg-success m-1">
                        {engagement.role}
                      </span><br/>
                    {/for}
                  </td>
                </tr>

                <tr :if={podcast.payment_link_url}>
                  <td>
                    <label class="text-xs py-1 px-1.5 text-white rounded bg-info m-1">
                      Support
                    </label>
                  </td>
                  <td>
                    <a href="podcast.payment_link_url">{podcast.payment_link_title}</a>
                  </td>
                </tr>
              </table>
            </div>

           <h5 class="text-lg">Description</h5>
           <p>{podcast.description}</p>

           {#if podcast.description != podcast.summary}
             <h5 class="text-lg">Summary</h5>
             <p>{podcast.summary}</p>
           {/if}
         </Panel>
        {/for}
      </div>
      <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    </Panel>
    """
  end
end
