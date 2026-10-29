defmodule PanWeb.Live.Admin.Category.Merge do
  use PanWeb, :admin_live_view
  alias Pan.Repo
  alias PanWeb.{Category, CategoryMapping, Endpoint}
  alias PanWeb.Component.{Tree, Icon}

  @empty_class "bg-warning/40"
  @best_candidate_class "bg-info/70"
  @candidate_class "bg-info/20"
  @no_title_class "bg-error/30"

  @tabs [{"merge", "Merge"}, {"mappings", "Mappings"}, {"icons", "Icons"}]
  @max_icon_matches 120

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(from_id: nil, into_id: nil, tabs: @tabs)
     |> assign(icon_id: nil, icon_query: "", icon_matches: [], icon_more: false)
     |> load()}
  end

  def handle_params(%{"tab" => tab}, _uri, socket) when tab in ["mappings", "icons"],
    do: {:noreply, assign(socket, tab: tab)}

  def handle_params(_params, _uri, socket), do: {:noreply, assign(socket, tab: "merge")}

  defp load(socket) do
    empty_ids = Category.empty_ids()

    namesakes =
      Map.new(Category.namesakes(), fn
        {id, true} -> {id, @best_candidate_class}
        {id, false} -> {id, @candidate_class}
      end)

    # blank titles are namesakes of each other, the no-title color wins
    no_title = Map.new(Category.no_title_ids(), &{&1, @no_title_class})
    marked = Map.merge(Map.new(empty_ids, &{&1, @empty_class}), no_title)

    assign(socket,
      categories: Category.tree(),
      mappings: CategoryMapping.list(),
      apple_badges: Map.new(Category.apple_ids(), &{&1, "Apple"}),
      podcast_counts: Category.podcast_counts(),
      empty_ids: empty_ids,
      marked: marked,
      from_marked: marked |> Map.merge(namesakes) |> Map.merge(no_title),
      empty_class: @empty_class,
      no_title_class: @no_title_class,
      best_candidate_class: @best_candidate_class,
      candidate_class: @candidate_class
    )
    |> mark_candidates()
  end

  # the right tree also shows the same-title categories of the left
  # selection, the one with the most podcasts stronger
  defp mark_candidates(%{assigns: %{from_id: nil, marked: marked}} = socket),
    do: assign(socket, into_marked: marked)

  defp mark_candidates(%{assigns: %{from_id: from_id, marked: marked}} = socket) do
    candidates =
      from_id
      |> Category.same_title_candidates()
      |> Enum.with_index()
      |> Map.new(fn
        {{id, _count}, 0} -> {id, @best_candidate_class}
        {{id, _count}, _index} -> {id, @candidate_class}
      end)

    assign(socket, into_marked: Map.merge(marked, candidates))
  end

  def handle_event("merge", _, %{assigns: %{from_id: from_id, into_id: into_id}} = socket)
      when is_nil(from_id) or is_nil(into_id) do
    {:noreply, put_flash(socket, :error, "Select both categories first.")}
  end

  def handle_event("merge", _, %{assigns: assigns} = socket) do
    case Category.merge(assigns.from_id, assigns.into_id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Categories merged.")
         |> assign(from_id: nil, into_id: nil)
         |> load()}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("move_into", _, %{assigns: %{from_id: from_id, into_id: into_id}} = socket)
      when is_nil(from_id) or is_nil(into_id) do
    {:noreply, put_flash(socket, :error, "Select both categories first.")}
  end

  def handle_event("move_into", _, %{assigns: assigns} = socket) do
    case Category.move_into(assigns.from_id, assigns.into_id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Category moved.")
         |> assign(from_id: nil, into_id: nil)
         |> load()}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("delete", _, %{assigns: %{from_id: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Select the category to delete on the left first.")}
  end

  def handle_event("delete", _, %{assigns: %{from_id: from_id}} = socket) do
    case Category.delete_empty(from_id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Category deleted.")
         |> assign(from_id: nil, into_id: nil)
         |> load()}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("update_apple", _, socket) do
    case Pan.AppleCategories.update() do
      {:ok, result} ->
        {:noreply, socket |> put_flash(:info, apple_message(result)) |> load()}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("fill_icons", _, socket) do
    %{icons: icons, colors: colors} = Pan.CategoryIcons.fill_missing()

    {:noreply,
     socket
     |> put_flash(:info, "Filled #{icons} empty icons and #{colors} empty colors.")
     |> load()}
  end

  def handle_event("delete_mapping", %{"id" => id}, socket) do
    CategoryMapping.delete(String.to_integer(id))
    {:noreply, socket |> put_flash(:info, "Mapping deleted.") |> load()}
  end

  def handle_event("pick_category", %{"id" => id}, socket) do
    id = String.to_integer(id)
    {category, _color, _top_level} = find_row(socket.assigns.categories, id)
    query = category.icon || (category.title || "") |> String.split() |> List.first("")
    {:noreply, socket |> assign(icon_id: id) |> search_icons(query)}
  end

  def handle_event("search_icons", %{"query" => query}, socket),
    do: {:noreply, search_icons(socket, query)}

  def handle_event("set_icon", %{"icon" => icon}, socket),
    do: {:noreply, update_category(socket, %{icon: blank_to_nil(icon)})}

  def handle_event("set_color", %{"color" => color}, socket),
    do: {:noreply, update_category(socket, %{color: blank_to_nil(color)})}

  def handle_event("selectFrom", %{"node-id" => from_id}, socket) do
    {:noreply, socket |> assign(from_id: String.to_integer(from_id)) |> mark_candidates()}
  end

  def handle_event("selectInto", %{"node-id" => into_id}, socket) do
    {:noreply, assign(socket, into_id: into_id |> String.to_integer())}
  end

  # Icons tab (backlog.md #439): names containing the query, those starting
  # with it first
  defp search_icons(socket, query) do
    needle = query |> String.trim() |> String.downcase()

    matches =
      if String.length(needle) < 2 do
        []
      else
        PanWeb.Live.Icon.names()
        |> Enum.filter(&String.contains?(&1, needle))
        |> Enum.sort_by(&{not String.starts_with?(&1, needle), &1})
        |> Enum.take(@max_icon_matches + 1)
      end

    assign(socket,
      icon_query: query,
      icon_matches: Enum.take(matches, @max_icon_matches),
      icon_more: length(matches) > @max_icon_matches
    )
  end

  defp update_category(%{assigns: %{icon_id: id}} = socket, attrs) do
    case Category |> Repo.get!(id) |> Category.changeset(attrs) |> Repo.update() do
      {:ok, _category} ->
        load(socket)

      {:error, changeset} ->
        put_flash(socket, :error, "Not saved: #{inspect(changeset.errors)}")
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  # {category, color shown, top level?} for the top level categories and
  # their children, subcategories in their parent's color
  defp rows(categories) do
    Enum.flat_map(categories, fn category ->
      [
        {category, category.color, true}
        | Enum.map(category.children, &{&1, category.color, false})
      ]
    end)
  end

  defp find_row(categories, id), do: Enum.find(rows(categories), &(elem(&1, 0).id == id))

  defp color_class(nil), do: ""
  defp color_class(color), do: "text-ctp-#{color}"

  defp apple_message(%{apple: apple, flagged: flagged, unflagged: unflagged, missing: missing}) do
    "#{apple} Apple categories (#{flagged} newly flagged, #{unflagged} unflagged)." <>
      if missing == [],
        do: "",
        else: " On Apple's list, not here yet: " <> Enum.join(missing, ", ") <> "."
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl m-4">Merging categories</h1>

    <div role="tablist" class="tabs tabs-border mx-4">
      <.link
        :for={{key, label} <- @tabs}
        patch={category_path(Endpoint, :merge, tab: key)}
        role="tab"
        class={["tab", key == @tab && "tab-active"]}
      >
        {label}
        <span :if={key == "mappings"} class="badge badge-sm badge-outline badge-neutral ml-2">
          {length(@mappings)}
        </span>
      </.link>
    </div>

    <div :if={@tab == "merge"} class="flex m-4 space-x-4">
      <.live_component
        module={Tree}
        id="fromTree"
        nodes={@categories}
        select="selectFrom"
        selected_id={@from_id}
        marked={@from_marked}
        counts={@podcast_counts}
        badges={@apple_badges}
      />
      <.live_component
        module={Tree}
        id="intoTree"
        nodes={@categories}
        select="selectInto"
        selected_id={@into_id}
        marked={@into_marked}
        counts={@podcast_counts}
        badges={@apple_badges}
      />

      <div class="sticky top-4 self-start">
        <button phx-click="merge" class="btn btn-warning btn-sm block">
          <Icon.render name="folder" />
          <Icon.render name="arrow-right" />
          <Icon.render name="folder" /> Merge Categories
        </button>

        <button
          phx-click="move_into"
          disabled={is_nil(@from_id) or is_nil(@into_id)}
          class="btn btn-info btn-sm mt-4 block"
        >
          <Icon.render name="folder" />
          <Icon.render name="arrow-right" />
          <Icon.render name="folder-open" /> Move into (left → right)
        </button>

        <button
          phx-click="delete"
          data-confirm="Delete the category selected on the left?"
          disabled={not MapSet.member?(@empty_ids, @from_id)}
          class="btn btn-error btn-sm mt-4 block"
        >
          Delete Category (left)
        </button>

        <button phx-click="update_apple" class="btn btn-neutral btn-sm mt-4 block">
          Update Apple flags
        </button>

        <button phx-click="fill_icons" class="btn btn-neutral btn-sm mt-4 block">
          Fill missing icons
        </button>

        <ul class="mt-6 space-y-1 text-sm">
          <li class="flex items-center gap-2">
            <span class="badge badge-xs badge-outline badge-neutral">Apple</span>
            on Apple Podcasts' current list: merge into it, it can't be deleted, merged away or moved
          </li>
          <li class="flex items-center gap-2">
            <span class="inline-block size-4 border border-base-300 bg-success"></span> selected
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-base-300", @empty_class]}></span>
            empty (no podcasts, subcategories, follows, likes or community), can be deleted
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-base-300", @no_title_class]}></span>
            no title (blank, "0"), merge into the parent or Uncategorized
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-base-300", @best_candidate_class]}></span>
            left: most podcasts of its title; right: of the left selection's namesakes
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-base-300", @candidate_class]}></span>
            left: has a namesake with more podcasts; right: other namesakes of the left selection
          </li>
        </ul>
      </div>
    </div>

    <div :if={@tab == "mappings"} class="m-4">
      <p class="text-sm my-2 max-w-3xl">
        Feeds using a name on the left get the category on the right instead, the name isn't created
        again. A subcategory below a mapped parent needs its own mapping, else it's skipped.
        Merging records the merged category's names here.
      </p>

      <p :if={@mappings == []} class="text-sm italic">No mappings yet.</p>

      <table :if={@mappings != []} id="category-mappings" class="table table-sm w-auto">
        <thead>
          <tr>
            <th>Name in feeds</th>
            <th>Filed under</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={mapping <- @mappings} id={"category-mapping-#{mapping.id}"}>
            <td>{names(mapping.parent_title, mapping.title)}</td>
            <td>
              {names(mapping.category.parent && mapping.category.parent.title, mapping.category.title)}
            </td>
            <td>
              <button
                phx-click="delete_mapping"
                phx-value-id={mapping.id}
                data-confirm="Delete this mapping? Feeds using the name create it again."
                class="btn btn-error btn-xs"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div :if={@tab == "icons"} class="flex items-start gap-6 m-4">
      <table id="category-icons" class="table table-sm w-auto">
        <tbody>
          <tr
            :for={{category, color, top_level} <- rows(@categories)}
            id={"category-icon-#{category.id}"}
            class={category.id == @icon_id && "bg-base-200"}
          >
            <td class={not top_level && "pl-10"}>
              <button
                phx-click="pick_category"
                phx-value-id={category.id}
                class="link link-hover flex items-center gap-2 text-left"
              >
                <Icon.render name={category.icon || "folder"} class={color_class(color)} />
                {category.title}
              </button>
            </td>
            <td class="text-xs opacity-70">{category.icon}</td>
            <td class="text-xs opacity-70">{top_level && category.color}</td>
          </tr>
        </tbody>
      </table>

      <.icon_editor
        :if={@icon_id}
        row={find_row(@categories, @icon_id)}
        query={@icon_query}
        matches={@icon_matches}
        more={@icon_more}
      />
    </div>
    """
  end

  attr :row, :any, required: true
  attr :query, :string, required: true
  attr :matches, :list, required: true
  attr :more, :boolean, required: true

  defp icon_editor(%{row: {selected, color, top_level}} = assigns) do
    assigns = assign(assigns, selected: selected, color: color, top_level: top_level)

    ~H"""
    <div
      id="icon-editor"
      class="card bg-base-100 shadow-sm sticky top-4 w-xl shrink-0 p-4 space-y-4"
    >
      <h2 class="font-semibold text-lg flex items-center gap-2">
        <Icon.render name={@selected.icon || "folder"} class={"h-8 w-8 " <> color_class(@color)} />
        {@selected.title}
      </h2>

      <div :if={@top_level} class="flex flex-wrap items-center gap-2">
        <button
          :for={option <- Category.colors()}
          phx-click="set_color"
          phx-value-color={option}
          title={option}
          class={[
            "size-7 rounded-full bg-current",
            color_class(option),
            option == @selected.color && "ring-2 ring-base-content ring-offset-2 ring-offset-base-100"
          ]}
        ></button>
        <button
          :if={@selected.color}
          phx-click="set_color"
          phx-value-color=""
          class="btn btn-ghost btn-xs"
        >
          No color
        </button>
      </div>
      <p :if={not @top_level} class="text-sm opacity-70">
        Subcategories use their parent's color.
      </p>

      <form id="icon-search" phx-change="search_icons" phx-submit="search_icons">
        <input
          type="search"
          name="query"
          value={@query}
          phx-debounce="200"
          placeholder="Search icons, e.g. book"
          autocomplete="off"
          class="input input-sm w-full"
        />
      </form>

      <div class="grid grid-cols-8 gap-1">
        <button
          :for={name <- @matches}
          phx-click="set_icon"
          phx-value-icon={name}
          title={name}
          class={["btn btn-ghost btn-square", name == @selected.icon && "btn-active"]}
        >
          <Icon.render name={name} class={"h-6 w-6 " <> color_class(@color)} />
        </button>
      </div>
      <p class="text-xs opacity-70">
        {length(@matches)} shown{if @more, do: ", more match: narrow the search"}.
        Two letters at least.
      </p>

      <button
        :if={@selected.icon}
        phx-click="set_icon"
        phx-value-icon=""
        class="btn btn-ghost btn-sm"
      >
        <Icon.render name="folder" class={color_class(@color)} /> No icon (folder)
      </button>
    </div>
    """
  end

  defp names(nil, title), do: title
  defp names(parent_title, title), do: "#{parent_title} › #{title}"
end
