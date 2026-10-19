defmodule PanWeb.Live.Admin.Category.Merge do
  use PanWeb, :admin_live_view
  alias PanWeb.Category
  alias PanWeb.Component.{Tree, Icon}

  @empty_class "bg-warning/40"
  @best_candidate_class "bg-info/70"
  @candidate_class "bg-info/20"
  @no_title_class "bg-error/30"

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(from_id: nil, into_id: nil) |> load()}
  end

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

  def handle_event("selectFrom", %{"node-id" => from_id}, socket) do
    {:noreply, socket |> assign(from_id: String.to_integer(from_id)) |> mark_candidates()}
  end

  def handle_event("selectInto", %{"node-id" => into_id}, socket) do
    {:noreply, assign(socket, into_id: into_id |> String.to_integer())}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl m-4">Merging categories</h1>

    <div class="flex m-4 space-x-4">
      <.live_component
        module={Tree}
        id="fromTree"
        nodes={@categories}
        select="selectFrom"
        selected_id={@from_id}
        marked={@from_marked}
        counts={@podcast_counts}
      />
      <.live_component
        module={Tree}
        id="intoTree"
        nodes={@categories}
        select="selectInto"
        selected_id={@into_id}
        marked={@into_marked}
        counts={@podcast_counts}
      />

      <div class="sticky top-4 self-start">
        <button phx-click="merge" class="btn btn-warning btn-sm block">
          <Icon.render name="folder-heroicons-outline" />
          <Icon.render name="arrow-sm-right-heroicons-outline" />
          <Icon.render name="folder-heroicons-outline" /> Merge Categories
        </button>

        <button
          phx-click="delete"
          data-confirm="Delete the category selected on the left?"
          disabled={not MapSet.member?(@empty_ids, @from_id)}
          class="btn btn-error btn-sm mt-4 block"
        >
          Delete Category (left)
        </button>

        <ul class="mt-6 space-y-1 text-sm">
          <li class="flex items-center gap-2">
            <span class="inline-block size-4 border border-gray-light bg-success"></span> selected
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-gray-light", @empty_class]}></span>
            empty (no podcasts, subcategories, follows, likes or community), can be deleted
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-gray-light", @no_title_class]}></span>
            no title (blank, "0"), merge into the parent or Uncategorized
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-gray-light", @best_candidate_class]}></span>
            left: most podcasts of its title; right: of the left selection's namesakes
          </li>
          <li class="flex items-center gap-2">
            <span class={["inline-block size-4 border border-gray-light", @candidate_class]}></span>
            left: has a namesake with more podcasts; right: other namesakes of the left selection
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
