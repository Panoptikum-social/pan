defmodule PanWeb.Live.Search do
  use PanWeb, :live_view
  on_mount(PanWeb.Live.AssignUserAndAdmin)
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [icon: 1]
  alias PanWeb.Component.Pill
  alias PanWeb.Component.LinkButton
  alias Pan.Search
  alias Pan.Repo
  alias PanWeb.{Endpoint, Language, User}

  # only these two indices carry language_ids in Manticore (see
  # Pan.Search.Podcast/Episode) - categories/personas aren't language-specific
  @language_filterable_indices ~w(podcasts episodes)

  def mount(_params, _session, socket) do
    language_groups = user_language_groups(socket.assigns[:current_user_id])

    # default: "all my languages" - every group the user has saved is
    # selected; unchecking all of them is the deliberate escape hatch back
    # to an unrestricted search (see selected_language_ids/1)
    selected_representative_ids =
      language_groups |> Enum.map(& &1.representative_id) |> MapSet.new()

    {:ok,
     assign(socket,
       language_groups: language_groups,
       selected_representative_ids: selected_representative_ids
     )}
  end

  defp user_language_groups(nil), do: []

  defp user_language_groups(user_id) do
    Repo.get(User, user_id)
    |> Repo.preload(:languages)
    |> case do
      nil ->
        []

      user ->
        user.languages
        |> Enum.group_by(&Language.group_key/1)
        |> Enum.map(fn {{name, emoji}, languages} ->
          ids = languages |> Enum.map(& &1.id) |> Enum.sort()
          %{name: name, emoji: emoji, ids: ids, representative_id: hd(ids)}
        end)
        |> Enum.sort_by(& &1.name)
    end
  end

  defp selected_language_ids(%{assigns: assigns}) do
    if assigns.index in @language_filterable_indices do
      assigns.language_groups
      |> Enum.filter(&MapSet.member?(assigns.selected_representative_ids, &1.representative_id))
      |> Enum.flat_map(& &1.ids)
    else
      []
    end
  end

  defp fetch(%{assigns: %{page: page, per_page: per_page, index: index, term: term}} = socket) do
    hits =
      Search.query(
        index: index,
        term: term,
        limit: per_page,
        offset: (page - 1) * per_page,
        language_ids: selected_language_ids(socket)
      )

    assign(socket,
      hits: hits,
      total: hits["total"],
      hits_count: length(hits["hits"]),
      has_more: hits["total"] > page * per_page
    )
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

  def handle_event("toggle-language", %{"id" => id}, %{assigns: assigns} = socket) do
    id = String.to_integer(id)

    selected =
      if MapSet.member?(assigns.selected_representative_ids, id) do
        MapSet.delete(assigns.selected_representative_ids, id)
      else
        MapSet.put(assigns.selected_representative_ids, id)
      end

    {:noreply, apply_language_selection(socket, selected)}
  end

  def handle_event("select-all-languages", _, %{assigns: assigns} = socket) do
    selected = assigns.language_groups |> Enum.map(& &1.representative_id) |> MapSet.new()
    {:noreply, apply_language_selection(socket, selected)}
  end

  def handle_event("clear-language-filter", _, socket) do
    {:noreply, apply_language_selection(socket, MapSet.new())}
  end

  # fired by the LanguageFilterPersistence JS hook on page load, with
  # whatever selection (if any) it found in this browser's localStorage -
  # restores it instead of the page's "all my languages" default, so a
  # restriction picked during an earlier search carries over to the next
  # one. Restricted to ids that are still valid representative ids for this
  # user (their saved languages may have changed since it was stored).
  def handle_event("restore-language-filter", %{"ids" => ids}, %{assigns: assigns} = socket) do
    valid_ids = MapSet.new(assigns.language_groups, & &1.representative_id)
    selected = ids |> MapSet.new() |> MapSet.intersection(valid_ids)

    {:noreply,
     assign(socket, page: 1, update: "replace", selected_representative_ids: selected)
     |> fetch()}
  end

  # Dialyzer/OTP 28 false positive: MapSet.to_list/1 below spuriously fails
  # opaqueness checking on plain MapSets under OTP 28's stricter dialyzer -
  # not specific to this code. See https://github.com/elixir-lang/elixir/issues/14576
  # and https://elixirforum.com/t/function-call-without-opaqueness-type-mismatch-under-otp-28/72407
  @dialyzer {:no_opaque, apply_language_selection: 2}
  @spec apply_language_selection(Phoenix.LiveView.Socket.t(), MapSet.t(integer())) ::
          Phoenix.LiveView.Socket.t()
  defp apply_language_selection(socket, selected) do
    socket
    |> assign(page: 1, update: "replace", selected_representative_ids: selected)
    |> fetch()
    |> push_event("persist-language-filter", %{ids: MapSet.to_list(selected)})
  end

  defp language_filter_status(selected, groups) do
    cond do
      MapSet.size(selected) == 0 -> "searching in all languages available"
      MapSet.size(selected) == length(groups) -> "restricted to all your languages"
      true -> "restricted to your selected languages"
    end
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
        <.link
          :if={@index != "categories"}
          patch={search_frontend_path(Endpoint, :search, "categories", @term)}
          class="text-link hover:text-link-dark visited:text-mint"
        >
          categories
        </.link>
        {if @index != "categories", do: raw(" | ")}
        <.link
          :if={@index != "podcasts"}
          patch={search_frontend_path(Endpoint, :search, "podcasts", @term)}
          class="text-link hover:text-link-dark visited:text-mint"
        >
          podcasts
        </.link>
        {if @index != "podcasts", do: raw(" | ")}
        <.link
          :if={@index != "personas"}
          patch={search_frontend_path(Endpoint, :search, "personas", @term)}
          class="text-link hover:text-link-dark visited:text-mint"
        >
          personas
        </.link>
        {if @index not in ["personas", "episodes"], do: raw(" | ")}
        <.link
          :if={@index != "episodes"}
          patch={search_frontend_path(Endpoint, :search, "episodes", @term)}
          class="text-link hover:text-link-dark visited:text-mint"
        >
          episodes
        </.link>
        instead.<br />
        You can mask your search terms with an asterisk at the end or the beginning of the search term,
        as long as there are at least 3 characters left.
      </p>

      <div
        :if={@language_groups != [] and @index in ~w(podcasts episodes)}
        id="language-filter"
        phx-hook="LanguageFilterPersistence"
        class="mt-3 flex flex-wrap items-center gap-2"
      >
        <span class="text-sm font-mono">Languages:</span>
        <button
          :for={group <- @language_groups}
          type="button"
          phx-click="toggle-language"
          phx-value-id={group.representative_id}
          class={[
            "btn btn-xs",
            if(MapSet.member?(@selected_representative_ids, group.representative_id),
              do: "btn-primary",
              else: "btn-outline"
            )
          ]}
        >
          {group.emoji} {group.name}
        </button>
        <button
          :if={MapSet.size(@selected_representative_ids) < length(@language_groups)}
          type="button"
          phx-click="select-all-languages"
          class="btn btn-xs btn-ghost underline"
        >
          reset to all my languages
        </button>
        <button
          :if={MapSet.size(@selected_representative_ids) > 0}
          type="button"
          phx-click="clear-language-filter"
          class="btn btn-xs btn-ghost underline"
        >
          search in all languages available
        </button>
        <span class="text-xs text-gray-dark">
          ({language_filter_status(@selected_representative_ids, @language_groups)})
        </span>
      </div>
    </div>

    <ul
      id="search_results"
      phx-update={@update}
      class="flex flex-col divide-y divide-gray divide-dotted space-y-4 m-4"
    >
      <li
        :for={hit <- @hits["hits"]}
        id={"result-#{hit["_id"]}"}
        class="pt-4 flex flex-col xl:flex-row space-x-0 xl:space-x-4 space-y-4 xl:space-y-0"
      >
        <div
          :if={hit["_source"]["thumbnail_url"] not in [nil, ""]}
          class="flex-none p-2 my-2 border border-gray-light shadow mx-auto lg:mx-0"
        >
          <img
            src={"https://panoptikum.social#{hit["_source"]["thumbnail_url"]}"}
            class="wrap-break-word text-xs"
            height="150"
            width="150"
            alt={hit["_source"]["image_title"]}
            id={"photo-#{hit["_id"]}"}
          />
        </div>

        <div class="max-w-5xl">
          <h2 class="text-2xl">
            {heading(@index)}
            <a
              href={show_path(@index, hit["_id"])}
              class="text-link hover:text-link-dark visited:text-mint"
            >
              {hit["_source"]["title"] || hit["_source"]["name"]}
            </a>
            <span :if={hit["_source"]["languages"]}>
              <span :for={language <- hit["_source"]["languages"]}>{language["emoji"]}</span>
            </span>
          </h2>

          <p class="text-sm">
            <a
              href={show_path(@index, hit["_id"])}
              class="text-mint hover:text-mint-light"
            >
              https://panoptikum.social{show_path(@index, hit["_id"])}
            </a>
          </p>

          <table class="table w-auto text-sm">
            <%= for {highlight_key, highlight_values} <- hit["highlight"] do %>
              <tr :for={highlight_value <- highlight_values}>
                <td class="text-right align-top pr-4">{highlight_key |> String.capitalize()}</td>
                <td>{highlight_value |> raw}</td>
              </tr>
            <% end %>

            <tr :if={hit["_source"]["inserted_at"]}>
              <td class="text-right pr-4">Imported</td>
              <td>{hit["_source"]["inserted_at"] |> format_datetime()}</td>
            </tr>
          </table>

          <p :if={hit["_source"]["gigs"]} class="leading-9">
            <%= for gig <- hit["_source"]["gigs"] do %>
              <LinkButton.render
                to={persona_frontend_path(PanWeb.Endpoint, :show, gig["persona_id"])}
                class="bg-lavender text-white border border-gray-dark
                                hover:bg-lavender-light hover:border-lavender"
                icon="user-astronaut-lineawesome-solid"
                title={gig["persona_name"]}
              />
              <Pill.render type="lavender">{gig["role"]}</Pill.render>
            <% end %>
          </p>

          <LinkButton.render
            :if={hit["_source"]["podcast_id"]}
            to={podcast_frontend_path(PanWeb.Endpoint, :show, hit["_source"]["podcast_id"])}
            class="btn-outline"
            icon="podcast-lineawesome-solid"
            title={hit["_source"]["podcast"]["title"]}
            truncate={true}
          />

          <p :if={hit["_source"]["engagements"]} class="leading-9">
            <%= for engagement <- hit["_source"]["engagements"] do %>
              <LinkButton.render
                :if={@index == "podcasts"}
                to={persona_frontend_path(Endpoint, :show, engagement["persona_id"])}
                class="bg-lavender text-white border border-gray-dark
                                  hover:bg-lavender-light hover:border-lavender"
                icon="user-astronaut-lineawesome-solid"
                title={engagement["persona_name"]}
              />
              <LinkButton.render
                :if={@index != "podcasts"}
                to={podcast_frontend_path(Endpoint, :show, engagement["podcast_id"])}
                class="btn-outline"
                icon="podcast-lineawesome-solid"
                title={engagement["podcast_title"]}
              />
              <Pill.render type="lavender">{engagement["role"]}</Pill.render>
            <% end %>
          </p>

          <p :if={hit["_source"]["categories"]} class="leading-9">
            <LinkButton.render
              :for={category <- hit["_source"]["categories"]}
              to={category_frontend_path(Endpoint, :show, category["id"])}
              class="btn-outline"
              large={false}
              icon="folder-heroicons-outline"
              title={category["title"]}
              truncate={false}
            />
          </p>
        </div>
      </li>
    </ul>
    <div :if={@has_more} id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}>
    </div>
    """
  end
end
