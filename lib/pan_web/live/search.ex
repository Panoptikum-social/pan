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
    <h1 class="text-2xl m-4">{@total} {@index |> String.capitalize()} found for <i>{@term}</i></h1>
    <p class="m-4">
      You might want to search for
      <a :if={@index != "categories"}
         href={search_frontend_path(Endpoint, :search, "categories", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
         categories
      </a>
      {#if @index != "categories"} | {/if}
      <a :if={@index != "podcasts"}
         href={search_frontend_path(Endpoint, :search, "podcasts", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        podcasts
      </a>
      {#if @index != "podcasts"} | {/if}
      <a :if={@index != "personas"}
         href={search_frontend_path(Endpoint, :search, "personas", @term, page: 1)}
         class="text-link hover:text-link-dark visited:text-mint">
        personas
      </a>
      {#if @index not in ["personas", "episodes"] } | {/if}
      <a :if={@index != "episodes"}
          href={search_frontend_path(Endpoint, :search, "episodes", @term, page: 1)}
          class="text-link hover:text-link-dark visited:text-mint">
        episodes
      </a>
      instead.<br/>
      You can mask your search terms with an asterisk at the end or the beginning of the search term,
      as long as there are at least 3 characters left.
    </p>

    <table>
      <tbody id="search_results" phx-update="append">
        {#for hit <- @hits["hits"]}
          <tr id={"result-#{hit["_id"]}"}>
            <td class="p-4 align-top">
              <div :if={hit["_source"]["thumbnail_url"] not in [nil, ""]}>
                <img src={"https://panoptikum.io#{hit["_source"]["thumbnail_url"]}"}
                    class="ring-4 ring-gray rounded-xl"
                    height="120" width="120"
                    alt={hit["_source"]["image_title"]}
                    id={"photo-#{hit["_id"]}"}/>
              </div>
            </td>
            <td class="p-4 align-top max-w-screen-lg">
              <h3 class="text-2xl">
                {heading(@index)}
                <a href={show_path(@index, hit["_id"])}
                  class="text-link hover:text-link-dark visited:text-mint">
                  {hit["_source"]["title"]}
                </a>
                {#if hit["_source"]["languages"]}
                  {#for language <- hit["_source"]["languages"]}
                    {language["emoji"]}
                  {/for}
                {/if}
              </h3>

              <p class="text-sm">
                <a href={show_path(@index, hit["_id"])}
                  class="text-mint hover:text-mint-light">
                  https://panoptikum.io {show_path(@index, hit["_id"])}
                </a>
              </p>

              <table class="text-sm">
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

                  {#if @index == "podcasts"}
                    <LinkButton to={persona_frontend_path(Endpoint, :show, engagement["persona_id"])}
                                class="my-2 bg-lavender text-white border border-gray-dark
                                      hover:bg-lavender-light hover:border-lavender"
                                icon="user-astronaut-lineawesome-solid"
                                title={engagement["persona_name"]} />
                  {#else}
                    <LinkButton to={podcast_frontend_path(Endpoint, :show, engagement["podcast_id"])}
                                class="bg-white hover:bg-gray-lighter text-black border-gray"
                                icon="podcast-lineawesome-solid"
                                title={engagement["podcast_title"]} />
                  {/if}

                  <span class="text-xs font-semibold py-1 px-2 text-gray-darker uppercase rounded bg-lavender-light uppercase mr-1">
                    {engagement["role"]}
                  </span>
                {/for}
              </p>

              <p :if={hit["_source"]["categories"]}>
                {#for {category, index} <- Enum.with_index(hit["_source"]["categories"])}
                  {#if index > 0} &nbsp;·&nbsp; {/if}
                  <LinkButton to={category_frontend_path(Endpoint, :show, category["id"])}
                              class="bg-white hover:bg-gray-lighter text-gray-darker border-gray"
                              large={false}
                              icon="folder-heroicons-outline"
                              title={category["title"]}
                              truncate={false} />
                {/for}
              </p>
            </td>
          </tr>
        {/for}
      </tbody>
    </table>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
