defmodule PanWeb.Live.Podcast.Index do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  alias PanWeb.{Podcast, Endpoint}
  alias PanWeb.Surface.{Panel, CategoryButton, PersonaButton, Pill, Icon}

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

  defp thumbnail(podcast) do
    podcast.thumbnails |> List.first()
  end

  def render(assigns) do
    ~F"""
    <h1 class="text-3xl m-4">Latest Podcasts</h1>

    <div id="latest_podcasts" phx-update="append" class="m-4 grid grid-cols-1 md:grid-cols-2 2xl:grid-cols-3 gap-4">
      {#for podcast <- @latest_podcasts }
        <Panel purpose="podcast"
                id={"podcast-#{podcast.id}"}
                heading={podcast.title}
                target={podcast_frontend_path(Endpoint, :show, podcast.id)}>
          <div class="flex flex-col md:flex-row md:items-start md:space-x-2 mx-2 mt-4">
            <div class="flex-none p-2 xl:mx-4 my-2 xl:my-0 border border-gray-light shadow m-auto">
              {#if podcast.thumbnails != []}
                <img href={"https://panoptikum.io#{thumbnail(podcast).path}#{thumbnail(podcast).filename}"}
                    width="150" height="150" alt={podcast.image_title} id="photo"
                    class="break-words text-xs" />
              {#else}
                <img src="/images/missing-podcast.png" alt="missing image" width="150" height="150" />
              {/if}
            </div>

            <div class="grid grid-cols-3 grid-flow-row auto-rows-min">
              {#if podcast.website}
                <div>
                  <label class="text-xs py-1 px-1.5 text-white rounded bg-danger m-1">
                    Website
                  </label>
                </div>
                <div class="col-span-2"><a href={podcast.website}>{podcast.website}</a></div>
              {/if}

              <div>
                <label class="text-xs py-1 px-1.5 text-white rounded bg-info m-1">
                  Available&nbsp;since
                </label>
              </div>

              <div class="col-span-2">
                <Icon name="calendar-heroicons-outline"/>
                {Calendar.strftime(podcast.inserted_at, "%x")}
              </div>

              <div>
                <label class="text-xs py-1 px-1.5 text-white rounded bg-warning m-1">
                  Categories
                </label>
              </div>
              <div class="col-span-2 leading-9">
                {#for category <- podcast.categories}
                  <CategoryButton for={category}/>
                {/for}
              </div>

              <div>
                <label class="text-xs py-1 px-1.5 text-white rounded bg-aqua m-1">
                  Contributors
                </label>
              </div>
              <div class="leading-9 col-span-2">
                {#for engagement <- podcast.engagements}
                  <PersonaButton for={engagement.persona} />
                  <Pill type="success">{engagement.role}</Pill>
                {/for}
              </div>

              {#if podcast.payment_link_url}
                <div>
                  <label class="text-xs py-1 px-1.5 text-white rounded bg-info m-1">
                    Support
                  </label>
                </div>
                <div class="col-span-2">
                  <a href="podcast.payment_link_url">{podcast.payment_link_title}</a>
                </div>
              {/if}
            </div>
          </div>

          <div class="m-4">
            <h5 class="text-lg">Description</h5>
            <p>{podcast.description}</p>
            {#if podcast.description != podcast.summary}
              <h5 class="text-lg">Summary</h5>
              <p>{podcast.summary}</p>
            {/if}
          </div>
        </Panel>
      {/for}
    </div>
    <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
