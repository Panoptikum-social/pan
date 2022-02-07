defmodule PanWeb.Live.Search do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1]
  alias PanWeb.Surface.{LinkButton, Pill}
  alias Surface.Components.LivePatch
  alias Pan.Search
  alias PanWeb.Endpoint

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, index: index, term: term}} = socket) do
    hits = Search.query(index: index, term: term, limit: per_page, offset: (page - 1) * per_page)
    assign(socket, hits: hits, total: hits["total"], hits_count: hits["hits"] |> length)
  end

  def handle_params(
        %{"index" => index, "term" => term} = _params,
        _session,
        socket
      ) do
    {:noreply,
     assign(socket, page: 1, per_page: 10, index: index, term: term, update: "replace")
     |> fetch()}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1, update: "append") |> fetch()}
  end

  defp format_datetime(timestamp) do
    {:ok, date_time} = DateTime.from_unix(timestamp)
    Calendar.strftime(date_time, "%x")
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
      "episodes" -> (icon <> " Episode &nbsp;") |> raw
      "podcasts" -> (icon <> " Podcast &nbsp;") |> raw
      "categories" -> (icon <> " Category &nbsp;") |> raw
      "personas" -> (icon <> " Persona &nbsp;") |> raw
    end
  end

  def render(assigns) do
    ~F"""
    <div class="sticky top-0 z-50 bg-gray-lightest pb-2 p-6">
      <h1 class="text-3xl">{@total} {@index |> String.capitalize()} found for <i>{@term}</i></h1>
      <p class="mt-2">
        You might want to search for
        <LivePatch :if={@index != "categories"}
                  to={search_frontend_path(Endpoint, :search, "categories", @term)}
                  class="text-link hover:text-link-dark visited:text-mint">
          categories
        </LivePatch>
        {#if @index != "categories"} | {/if}
        <LivePatch :if={@index != "podcasts"}
                  to={search_frontend_path(Endpoint, :search, "podcasts", @term)}
                  class="text-link hover:text-link-dark visited:text-mint">
          podcasts
        </LivePatch>
        {#if @index != "podcasts"} | {/if}
        <LivePatch :if={@index != "personas"}
                  to={search_frontend_path(Endpoint, :search, "personas", @term)}
                  class="text-link hover:text-link-dark visited:text-mint">
          personas
        </LivePatch>
        {#if @index not in ["personas", "episodes"] } | {/if}
        <LivePatch :if={@index != "episodes"}
            to={search_frontend_path(Endpoint, :search, "episodes", @term)}
            class="text-link hover:text-link-dark visited:text-mint">
          episodes
        </LivePatch>
        instead.<br/>
        You can mask your search terms with an asterisk at the end or the beginning of the search term,
        as long as there are at least 3 characters left.
      </p>
    </div>

    <ul id="search_results" phx-update={@update}
        class="flex flex-col divide-y divide-gray divide-dotted space-y-4 m-4">
      {#for hit <- @hits["hits"]}
        <li id={"result-#{hit["_id"]}"} class="pt-4 flex flex-col xl:flex-row space-x-0 xl:space-x-4 space-y-4 xl:space-y-0">
          <div :if={hit["_source"]["thumbnail_url"] not in [nil, ""]}
               class="flex-none p-2 my-2 border border-gray-light shadow mx-auto lg:mx-0">
            <img src={"https://panoptikum.io#{hit["_source"]["thumbnail_url"]}"}
                class="break-words text-xs"
                height="150" width="150"
                alt={hit["_source"]["image_title"]}
                id={"photo-#{hit["_id"]}"}/>
          </div>

          <div class="max-w-screen-lg">
            <h2 class="text-2xl">
              {heading(@index)}
              <a href={show_path(@index, hit["_id"])}
                class="text-link hover:text-link-dark visited:text-mint">
                {hit["_source"]["title"] || hit["_source"]["name"]}
              </a>
              {#if hit["_source"]["languages"]}
                {#for language <- hit["_source"]["languages"]}
                  {language["emoji"]}
                {/for}
              {/if}
            </h2>

            <p class="text-sm">
              <a href={show_path(@index, hit["_id"])}
                class="text-mint hover:text-mint-light">
                https://panoptikum.io{show_path(@index, hit["_id"])}
              </a>
            </p>

            <table class="text-sm" cellpadding="4">
              {#for {highlight_key, highlight_values} <- hit["highlight"]}
                {#for highlight_value <- highlight_values}
                  <tr>
                    <td class="text-right align-top pr-4">{highlight_key |> String.capitalize}</td>
                    <td>{highlight_value |> raw}</td>
                  </tr>
                {/for}
              {/for}

              <tr :if={hit["_source"]["inserted_at"]}>
                <td class="text-right pr-4">Imported</td>
                <td>{hit["_source"]["inserted_at"] |> format_datetime()}</td>
              </tr>
            </table>

            <p class="leading-9" :if={hit["_source"]["gigs"]}>
              {#for gig <- hit["_source"]["gigs"]}
                <LinkButton to={persona_frontend_path(PanWeb.Endpoint, :show, gig["persona_id"])}
                            class="bg-lavender text-white border border-gray-dark
                                  hover:bg-lavender-light hover:border-lavender"
                            icon="user-astronaut-lineawesome-solid"
                            title={gig["persona_name"]} />
                <Pill type="lavender">{gig["role"]}</Pill>
              {/for}
            </p>

            <LinkButton :if={hit["_source"]["podcast_id"]}
                        to={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
                        class={"bg-white hover:bg-gray-lighter text-black border-gray"}
                        icon="podcast-lineawesome-solid"
                        title={hit["_source"]["podcast"]["title"]}
                        truncate={true} />

            <p :if={hit["_source"]["engagements"]} class="leading-9">
              {#for engagement <- hit["_source"]["engagements"]}
                {#if @index == "podcasts"}
                  <LinkButton to={persona_frontend_path(Endpoint, :show, engagement["persona_id"])}
                              class="bg-lavender text-white border border-gray-dark
                                    hover:bg-lavender-light hover:border-lavender"
                              icon="user-astronaut-lineawesome-solid"
                              title={engagement["persona_name"]} />
                {#else}
                  <LinkButton to={podcast_frontend_path(Endpoint, :show, engagement["podcast_id"])}
                              class="bg-white hover:bg-gray-lighter text-black border-gray"
                              icon="podcast-lineawesome-solid"
                              title={engagement["podcast_title"]} />
                {/if}
                <Pill type="lavender">{engagement["role"]}</Pill>
              {/for}
            </p>

            <p :if={hit["_source"]["categories"]} class="leading-9">
              {#for category <- hit["_source"]["categories"]}
                <LinkButton to={category_frontend_path(Endpoint, :show, category["id"])}
                            class="bg-white hover:bg-gray-lighter text-gray-darker border-gray"
                            large={false}
                            icon="folder-heroicons-outline"
                            title={category["title"]}
                            truncate={false} />
              {/for}
            </p>
          </div>
        </li>
      {/for}
    </ul>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
