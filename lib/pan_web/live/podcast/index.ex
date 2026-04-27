defmodule PanWeb.Live.Podcast.Index do
  use PanWeb, :live_view
  import PanWeb.Router.Helpers
  alias PanWeb.{Podcast, Endpoint}
  alias PanWeb.Component.Panel
  alias PanWeb.Component.Pill
  alias PanWeb.Component.Icon
  alias PanWeb.Component.PersonaButton
  alias PanWeb.Component.CategoryButton

  def mount(_params, _session, socket) do
    podcasts = Podcast.latest_for_index(1, 15)
    socket = assign(socket, page: 1, per_page: 15, page_title: "Latest Podcasts", has_more: length(podcasts) == 15)
    {:ok, stream(socket, :latest_podcasts, podcasts)}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    page = assigns.page + 1
    podcasts = Podcast.latest_for_index(page, assigns.per_page)
    {:noreply, socket |> assign(page: page, has_more: length(podcasts) == assigns.per_page) |> stream(:latest_podcasts, podcasts)}
  end

  defp thumbnail(podcast) do
    podcast.thumbnails |> List.first()
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl m-4">Latest Podcasts</h1>

    <div id="latest_podcasts" phx-update="stream" class="m-4 grid grid-cols-1 lg:grid-cols-2 gap-4">
      <Panel.render :for={{dom_id, podcast} <- @streams.latest_podcasts}
              purpose="podcast"
              id={dom_id}
              heading={podcast.title}
              target={podcast_frontend_path(Endpoint, :show, podcast.id)}>
        <div class="flex flex-col md:flex-row md:items-start md:space-x-2 mx-2 mt-4">
          <div class="flex-none p-2 xl:mx-4 my-2 xl:my-0 border border-gray-light shadow m-auto">
            <img :if={podcast.thumbnails != []}
                 src={"https://panoptikum.social#{thumbnail(podcast).path}#{thumbnail(podcast).filename}"}
                 width="150"
                 height="150"
                 alt={podcast.image_title}
                 id="photo"
                 class="wrap-break-word text-xs" />
            <img :if={podcast.thumbnails == []}
                 src="/images/missing-podcast.png" alt="missing image" width="150" height="150" />
          </div>

          <div class="grid grid-cols-3 grid-flow-row auto-rows-min">
            <div :if={podcast.website}>
              <label class="badge badge-error m-1">
                Website
              </label>
            </div>
            <div :if={podcast.website} class="col-span-2 wrap-break-word">
              <a href={podcast.website}>{podcast.website}</a>
            </div>

            <div>
              <label class="badge badge-info m-1">
                Available&nbsp;since
              </label>
            </div>

            <div class="col-span-2">
              <Icon.render name="calendar-heroicons-outline"/>
              {Calendar.strftime(podcast.inserted_at, "%x")}
            </div>

            <div>
              <label class="badge badge-warning m-1">
                Categories
              </label>
            </div>
            <div class="col-span-2 leading-9">
              <CategoryButton.render :for={category <- podcast.categories} for={category}/>
            </div>

            <div>
              <label class="badge m-1 bg-aqua text-white">
                Contributors
              </label>
            </div>
            <div class="leading-9 col-span-2">
              <span :for={engagement <- podcast.engagements}>
                <PersonaButton.render for={engagement.persona} />
                <Pill.render type="success">{engagement.role}</Pill.render>
              </span>
            </div>

            <div :if={podcast.payment_link_url}>
              <label class="badge badge-info m-1">
                Support
              </label>
            </div>
            <div :if={podcast.payment_link_url} class="col-span-2">
              <a href="podcast.payment_link_url">{podcast.payment_link_title}</a>
            </div>
          </div>
        </div>

        <div class="m-4">
          <h4 class="text-lg">Description</h4>
          <p>{podcast.description}</p>
          <div :if={podcast.description != podcast.summary}>
            <h4 class="text-lg">Summary</h4>
            <p>{podcast.summary}</p>
          </div>
        </div>
      </Panel.render>
    </div>
    <div :if={@has_more} id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
