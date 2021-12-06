defmodule PanWeb.Live.Search do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1]
  alias PanWeb.Surface.LinkButton
  alias Pan.Search
  alias PanWeb.Endpoint

  def mount(%{"index" => index, "term" => term} = params, _session, socket) do
    page = String.to_integer(params["page"] || "1")

    {:ok, assign(socket, page: page, per_page: 10, index: index, term: term) |> fetch()
     }
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, index: index, term: term}} = socket) do
    hits = Search.query(index: index, term: term, limit: per_page, offset: (page - 1) * per_page)
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

  def show_path(index, id) do
    case index do
      "episodes" ->
        episode_frontend_path(Endpoint, :show, id)
      "personas" ->
        persona_frontend_path(Endpoint, :show, id)
      "categories" ->
        category_frontend_path(Endpoint, :show, id)
      "podcasts" ->
        podcast_frontend_path(Endpoint, :show, id)
    end
  end

  defp heading(index) do
    {:safe, icon} =
    case index do
      "episodes" -> icon("headphones-lineawesome-solid")
      "podcasts" -> icon("podcast-lineawesome-solid")
      "categories" -> icon("folder-heroicons-outline")
      "personas" -> icon("user-astronaut-lineawesome-solid")
    end

    case index do
      "episodes" -> icon <> " Episode &nbsp;" |> raw
      "podcasts" -> icon <> " Podcast &nbsp;" |> raw
      "categories" -> icon <> " Category &nbsp;" |> raw
      "personas" -> icon <> " Persona &nbsp;" |> raw
    end
  end

  def render(assigns) do
    ~F"""
    <p class="m-4">Found {@total} {@index |> String.capitalize()}}.<br/>
      You might want to search for
      <a :if={@index != "categories"}
         href={search_frontend_path(Endpoint, :search, "categories", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
         categories
      </a>
      {#if @index in ["personas", "episodes"]} | {/if}
      <a :if={@index != "podcasts"}
         href={search_frontend_path(Endpoint, :search, "podcasts", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        podcasts
      </a>
      {#if @index in ["categories", "episodes"]} | {/if}
      <a :if={@index != "personas"}
         href={search_frontend_path(Endpoint, :search, "personas", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        personas
      </a>
      {#if @index in ["categories", "podcasts"]} | {/if}
      <a :if={@index != "episodes"}
          href={search_frontend_path(Endpoint, :search, "episodes", @term, page: 1)}
          class="text-link hover:text-link-dark visited:text-mint">
        episodes
      </a>
      instead.<br/>
      You can mask your search terms with an asterisk at the end or the beginning of the search term,
      as long as there are at least 3 characters left.
    </p>

    <div id="search_results" phx-update="append">
      {#for hit <- @hits["hits"]}
        <div id={"result-#{hit["_id"]}"}
             class="m-8">

          {#if hit["_source"]["thumbnail_url"]}
            <img src={"https://panoptikum.io" <> hit["_source"]["thumbnail_url"]}
                height="120"
                alt={hit["_source"]["image_title"]}
                class="thumbnail",
                id={"photo-#{hit["_id"]}"}/>
         {/if}

          <h3 class="text-2xl"
              style="margin-bottom: 5px; margin-top: 0px;">
           {heading(@index)}
            <a href={show_path(@index, hit["_id"])}
              class="text-link hover:text-link-dark visited:text-mint">
              {hit["_source"]["title"]}
            </a>
            {#for language <- hit["_source"]["languages"]} {language["emoji"]} {/for}
          </h3>

          <p class="text-sm">
            <a href={show_path(@index, hit["_id"])}
              class="text-mint hover:text-mint-light">
              https://panoptikum.io {show_path(@index, hit["_id"])}
            </a>
          </p>

          <table class="text-sm">format_date
            {#for {highlight_key, highlight_values} <- hit["highlight"]}
              {#for highlight_value <- highlight_values}
                <tr>
                  <td class="text-right pr-4">{highlight_key |> String.capitalize}</td>
                  <td>{highlight_value |> raw}</td>
                </tr>
              {/for}
            {/for}

            <tr :if={hit["_source"]["inserted_at"]}>
              <td class="text-right pr-4">Imported</td>
              <td>{hit["_source"]["inserted_at"] |> format_datetime()}</td>
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
                <span class="text-xs font-semibold py-1 px-2 text-gray-darker uppercase rounded bg-lavender-light uppercase mr-1">
                  {gig["role"]}
                </span>
              {/for}
            </p>
          {/if}

          <LinkButton :if={hit["_source"]["podcast_id"]}
                      to={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
                      class={"bg-white hover:bg-gray-lighter text-black border-gray"}
                      icon="podcast-lineawesome-solid"
                      title={hit["_source"]["podcast"]["title"]}
                      truncate={true} />

          <p :if={hit["_source"]["engagements"]}>
            {#for {engagement, index} <- Enum.with_index(hit["_source"]["engagements"])}
              {#if index > 0} &nbsp;·&nbsp; {/if}

              <LinkButton to={persona_frontend_path(PanWeb.Endpoint, :show, engagement["persona_id"])}
                          class="my-2 bg-lavender text-white border border-gray-dark
                                hover:bg-lavender-light hover:border-lavender"
                          icon="user-astronaut-lineawesome-solid"
                          title={engagement["persona_name"]} />

              <span class="text-xs font-semibold py-1 px-2 text-gray-darker uppercase rounded bg-lavender-light uppercase mr-1">
                {engagement["role"]}
              </span>
            {/for}
          </p>


          {#for {category, index} <- Enum.with_index(hit["_source"]["categories"])}
            {#if index > 0} &nbsp;·&nbsp; {/if}
            <LinkButton to={category_frontend_path(Endpoint, :show, category["id"])}
                        class="bg-white hover:bg-gray-lighter text-gray-darker border-gray"
                        large={false}
                        icon="folder-heroicons-outline"
                        title={category["title"]}
                        truncate={false} />
          {/for}
        </div>
      {/for}
    </div>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    {#for _index <- 1..8}<p class="h-24"/>{/for}
    """
  end
end
