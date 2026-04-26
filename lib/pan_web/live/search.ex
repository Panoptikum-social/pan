defmodule PanWeb.Live.Search do
  use PanWeb, :live_view
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1]
  alias PanWeb.Component.Pill
  alias PanWeb.Component.LinkButton
  alias Pan.Search
  alias PanWeb.Endpoint

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, index: index, term: term}} = socket) do
    hits = Search.query(index: index, term: term, limit: per_page, offset: (page - 1) * per_page)
    assign(socket, hits: hits, total: hits["total"], hits_count: length(hits["hits"]), has_more: hits["total"] > page * per_page)
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
      "episodes" -> episode_frontend_path(Endpoint, :show, id)
      "personas" -> persona_frontend_path(Endpoint, :show, id)
      "categories" -> category_frontend_path(Endpoint, :show, id)
      "podcasts" -> podcast_frontend_path(Endpoint, :show, id)
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
    ~H"""
    <div class="sticky top-0 z-50 bg-gray-lightest pb-2 p-6">
      <h1 class="text-3xl">{@total} {@index |> String.capitalize()} found for <i>{@term}</i></h1>
      <p class="mt-2">
        You might want to search for
        <.link :if={@index != "categories"}
                patch={search_frontend_path(Endpoint, :search, "categories", @term)}
                class="text-link hover:text-link-dark visited:text-mint">
          categories
        </.link>
        {if @index != "categories", do: raw(" | ")}
        <.link :if={@index != "podcasts"}
               patch={search_frontend_path(Endpoint, :search, "podcasts", @term)}
               class="text-link hover:text-link-dark visited:text-mint">
          podcasts
        </.link>
        {if @index != "podcasts", do: raw(" | ")}
        <.link :if={@index != "personas"}
                patch={search_frontend_path(Endpoint, :search, "personas", @term)}
                class="text-link hover:text-link-dark visited:text-mint">
          personas
        </.link>
        {if @index not in ["personas", "episodes"], do: raw(" | ")}
        <.link :if={@index != "episodes"}
               patch={search_frontend_path(Endpoint, :search, "episodes", @term)}
               class="text-link hover:text-link-dark visited:text-mint">
          episodes
        </.link>
        instead.<br/>
        You can mask your search terms with an asterisk at the end or the beginning of the search term,
        as long as there are at least 3 characters left.
      </p>
    </div>

    <ul id="search_results" phx-update={@update}
        class="flex flex-col divide-y divide-gray divide-dotted space-y-4 m-4">
      <li :for={hit <- @hits["hits"]}
          id={"result-#{hit["_id"]}"}
          class="pt-4 flex flex-col xl:flex-row space-x-0 xl:space-x-4 space-y-4 xl:space-y-0">
        <div :if={hit["_source"]["thumbnail_url"] not in [nil, ""]}
             class="flex-none p-2 my-2 border border-gray-light shadow mx-auto lg:mx-0">
          <img src={"https://panoptikum.social#{hit["_source"]["thumbnail_url"]}"}
              class="wrap-break-word text-xs"
              height="150" width="150"
              alt={hit["_source"]["image_title"]}
              id={"photo-#{hit["_id"]}"}/>
        </div>

        <div class="max-w-5xl">
          <h2 class="text-2xl">
            {heading(@index)}
            <a href={show_path(@index, hit["_id"])}
              class="text-link hover:text-link-dark visited:text-mint">
              {hit["_source"]["title"] || hit["_source"]["name"]}
            </a>
            <span :if={hit["_source"]["languages"]}>
              <span :for={language <- hit["_source"]["languages"]}>{language["emoji"]}</span>
            </span>
          </h2>

          <p class="text-sm">
            <a href={show_path(@index, hit["_id"])}
              class="text-mint hover:text-mint-light">
              https://panoptikum.social{show_path(@index, hit["_id"])}
            </a>
          </p>

          <table class="table w-auto text-sm">
            <%= for {highlight_key, highlight_values} <- hit["highlight"] do %>
              <tr :for={highlight_value <- highlight_values}>
                <td class="text-right align-top pr-4">{highlight_key |> String.capitalize}</td>
                <td>{highlight_value |> raw}</td>
              </tr>
            <% end %>

            <tr :if={hit["_source"]["inserted_at"]}>
              <td class="text-right pr-4">Imported</td>
              <td>{hit["_source"]["inserted_at"] |> format_datetime()}</td>
            </tr>
          </table>

          <p class="leading-9" :if={hit["_source"]["gigs"]}>
            <%= for gig <- hit["_source"]["gigs"] do %>
              <LinkButton.render to={persona_frontend_path(PanWeb.Endpoint, :show, gig["persona_id"])}
                          class="bg-lavender text-white border border-gray-dark
                                hover:bg-lavender-light hover:border-lavender"
                          icon="user-astronaut-lineawesome-solid"
                          title={gig["persona_name"]} />
              <Pill.render type="lavender">{gig["role"]}</Pill.render>
            <% end %>
          </p>

          <LinkButton.render :if={hit["_source"]["podcast_id"]}
                      to={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
                      class="btn-ghost"
                      icon="podcast-lineawesome-solid"
                      title={hit["_source"]["podcast"]["title"]}
                      truncate={true} />

          <p :if={hit["_source"]["engagements"]} class="leading-9">
            <%= for engagement <- hit["_source"]["engagements"] do %>
              <LinkButton.render :if={@index == "podcasts"}
                            to={persona_frontend_path(Endpoint, :show, engagement["persona_id"])}
                            class="bg-lavender text-white border border-gray-dark
                                  hover:bg-lavender-light hover:border-lavender"
                            icon="user-astronaut-lineawesome-solid"
                            title={engagement["persona_name"]} />
              <LinkButton.render :if={@index != "podcasts"}
                            to={podcast_frontend_path(Endpoint, :show, engagement["podcast_id"])}
                            class="btn-ghost"
                            icon="podcast-lineawesome-solid"
                            title={engagement["podcast_title"]} />
              <Pill.render type="lavender">{engagement["role"]}</Pill.render>
            <% end %>
          </p>

          <p :if={hit["_source"]["categories"]} class="leading-9">
            <LinkButton.render :for={category <- hit["_source"]["categories"]}
                        to={category_frontend_path(Endpoint, :show, category["id"])}
                        class="btn-ghost"
                        large={false}
                        icon="folder-heroicons-outline"
                        title={category["title"]}
                        truncate={false} />
          </p>
        </div>
      </li>
    </ul>
    <div :if={@has_more} id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
