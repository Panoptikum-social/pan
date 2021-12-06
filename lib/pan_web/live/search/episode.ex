defmodule PanWeb.Live.Search.Episode do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1]
  alias PanWeb.Surface.LinkButton
  alias Pan.Search
  alias PanWeb.Endpoint

  def mount(%{"term" => term} = params, _session, socket) do
    page = String.to_integer(params["page"] || "1")

    {:ok, assign(socket, page: page, per_page: 10, term: term) |> fetch()
     }
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, term: term}} = socket) do
    hits = Search.query(index: "episodes", term: term, limit: per_page, offset: (page - 1) * per_page)
    assign(socket, hits: hits, total: hits["total"], hits_count: hits["hits"] |> length)
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  defp format_datetime(timestamp) do
    {:ok, date_time} = DateTime.from_unix(timestamp)

    Timex.to_date(date_time)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end

  def render(assigns) do
    ~F"""
    <p class="m-4">Found {@total} Episodes.<br/>
      You might want to search for
      <a href={search_frontend_path(Endpoint, :search, "categories", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
         categories
      </a> |
      <a href={search_frontend_path(Endpoint, :search, "podcasts", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        podcasts
      </a> |
      <a href={search_frontend_path(Endpoint, :search, "personas", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        personas
      </a>
      instead.<br/>
      You can mask your search terms with an asterisk at the end or the beginning of the search term,
      as long as there are at least 3 characters left.
    </p>

    <div id="search_results" phx-update="append">
      {#for hit <- @hits["hits"]}
        <div id={"episode-#{hit["_id"]}"}
             class="m-8">
          <h3 class="text-2xl"
              style="margin-bottom: 5px; margin-top: 0px;">
            {icon("headphones-lineawesome-solid")} Episode &nbsp;
            <a href={episode_frontend_path(Endpoint, :show, hit["_id"])}
              class="text-link hover:text-link-dark visited:text-mint">
              {hit["_source"]["title"]}
            </a>
            {#for language <- hit["_source"]["languages"]} {language["emoji"]} {/for}
          </h3>

          <p class="text-sm">
            <a href={episode_frontend_path(Endpoint, :show, hit["_id"])}
              class="text-mint hover:text-mint-light">
              https://panoptikum.io {episode_frontend_path(Endpoint, :show, hit["_id"])}
            </a>
          </p>

          <table class="text-sm">
            {#for {highlight_key, highlight_values} <- hit["highlight"]}
              {#for highlight_value <- highlight_values}
                <tr>
                  <td class="text-right pr-4">{String.capitalize(highlight_key)}</td>
                  <td>{raw(highlight_value)}</td>
                </tr>
              {/for}
            {/for}

            <tr>
              <td class="text-right pr-4">Imported</td>
              <td>{format_datetime(hit["_source"]["inserted_at"])}</td>
            </tr>
          </table>

          {#if hit["_source"]["gigs"]}
            <p>
              {#for {gig, index} <- Enum.with_index(hit["_source"]["gigs"])}
                {#if index > 0}&nbsp;·&nbsp;{/if}

                <LinkButton to={persona_frontend_path(PanWeb.Endpoint, :show, gig["persona_id"])}
                            class="my-2 bg-lavender text-white border border-gray-dark
                                  hover:bg-lavender-light hover:border-lavender"
                            icon="user-astronaut-lineawesome-solid"
                            title={gig["persona_name"]} />
                <span class="label label-success">{gig["role"]}</span>
              {/for}
            </p>
          {/if}

          <LinkButton to={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
                      class={"bg-white hover:bg-gray-lighter text-black border-gray"}
                      icon="podcast-lineawesome-solid"
                      title={hit["_source"]["podcast"]["title"]}
                      truncate={true} />
        </div>
      {/for}
    </div>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    {#for _index <- 1..8}<p class="h-24"/>{/for}
    """
  end
end
