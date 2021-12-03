defmodule PanWeb.Live.Search.Episode do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1, truncate_string: 2]
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
    <p>Showing {@hits_count} Episodes
      (Nr. {(@page - 1) * @per_page + 1} to {(@page - 1) * @per_page + @hits_count} of {@total}). You might want to search for
      <a href={search_frontend_path(Endpoint, :search, "categories", @term, page: 1)}>categories</a> |
      <a href={search_frontend_path(Endpoint, :search, "podcasts", @term, page: 1)}>podcasts</a> |
      <a href={search_frontend_path(Endpoint, :search, "personas", @term, page: 1)}>personas</a>
      instead.
    </p>

    <p>
      You can mask your search terms with an asterisk at the end or the beginning of the search term,
      as long as there are 3 characters left.<br/>
      So "sciece", "sci*", "*sci" or "*ien*" will work, while "*ce" will not.
    </p>

    <div id="search_results" phx-update="append">
      {#for hit <- @hits["hits"]}
        <div id={"episode-#{hit["_id"]}"}>
          <hr/>

          <h3 style="margin-bottom: 5px; margin-top: 0px;">
            {icon("headphones-lineawesome-solid")} Episode &nbsp;
            <a href={episode_frontend_path(Endpoint, :show, hit["_id"])} style="color:#1a0dab">
              {hit["_source"]["title"]},
            </a>
            {#for language <- hit["_source"]["languages"]}>
            {language["emoji"]}
            {/for}
          </h3>

          <p class="small">
            <a href={episode_frontend_path(PanWeb.Endpoint, :show, hit["_id"])} style="color:#006621">
              https://panoptikum.io {episode_frontend_path(PanWeb.Endpoint, :show, hit["_id"])}
            </a>
          </p>

          {#for {highlight_key, highlight_values} <- hit["highlight"]}
            {#if highlight_values != []}
              {#for highlight_value <- highlight_values}
                <p class="small" style="margin-bottom: 1px;">
                  <i>{String.capitalize(highlight_key)}:</i>
                  {raw(highlight_value)}
                </p>
              {/for}
            {/if}
          {/for}

          <p class="small">
            <i>Episode captured:</i> {format_datetime(hit["_source"]["inserted_at"])}
          </p>

          {#for {gig, index} <- Enum.with_index(hit["_source"]["gigs"])}
            {#if index > 0}
              &nbsp;·&nbsp;
            {/if}

            <a href={persona_frontend_path(PanWeb.Endpoint, :show, gig["persona_id"])} class="btn btn-xs btn-lavender">
              {icon("user-astronaut-lineawesome-solid")} {gig["persona_name"]}
            </a>
            <span class="label label-success">{gig["role"]}</span>
          {/for}

          <hr style="margin-top: -15px; visibility:hidden;" />

          <a href={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
            class="btn btn-default btn-xs"
            style="color: #000">
            {icon("podcast-lineawesome-solid")} {truncate_string(hit["_source"]["podcast"]["title"], 50)}
          </a>
        </div>
      {/for}
    </div>
    <div id="infinite-scroll" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
