defmodule PanWeb.Live.Moderation.Moderate do
  use PanWeb, :live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{CategoryPodcast, Feed, Moderation, Podcast}
  alias PanWeb.Admin.Naming
  alias PanWeb.Admin.ModerationGrid
  alias PanWeb.Router.Helpers, as: Routes

  def mount(%{"id" => id}, session, socket) do
    moderation = Moderation.get_by_catagory_id_and_user_id(id, session["user_id"])

    columns = [
      :id,
      :title,
      :last_build_date,
      :blocked,
      :update_paused,
      :update_intervall,
      :next_update,
      :next_podcast_update,
      :retired,
      :failure_count,
      :unique_identifier,
      :episodes_count,
      :followers_count,
      :likes_count,
      :subscriptions_count,
      :latest_episode_publishing_date,
      :publication_frequency,
      :manually_updated_at,
      :full_text,
      :thumbnailed,
      :last_error_message,
      :last_error_occured,
      :inserted_at,
      :updated_at
    ]

    cols =
      Enum.map(
        columns,
        &%{
          field: &1,
          label: Naming.title_from_field(&1),
          type: Naming.type_of_field(Podcast, &1),
          searchable: true,
          sortable: true
        }
      )

    podcast_ids = Podcast.ids_by_category_id(id)

    if moderation do
      {:ok,
       assign(socket,
         category: moderation.community.category,
         cols: cols,
         podcast_ids: podcast_ids,
         existing_search_term: "",
         existing_search_results: []
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_info({:count, id: id, module: module}, socket) do
    send_update(module, id: id, count: :now)
    {:noreply, socket}
  end

  def handle_info({:show_episodes, podcast_id}, socket) do
    category_id = socket.assigns[:category].id

    episode_grid_path =
      Routes.moderation_frontend_path(socket, :episode_grid, category_id, podcast_id)

    {:noreply, push_navigate(socket, to: episode_grid_path)}
  end

  def handle_info({:show_feeds, podcast_id}, socket) do
    category_id = socket.assigns[:category].id
    feed_grid_path = Routes.moderation_frontend_path(socket, :feed_grid, category_id, podcast_id)
    {:noreply, push_navigate(socket, to: feed_grid_path)}
  end

  def handle_info({:edit_podcast, podcast_id}, socket) do
    category_id = socket.assigns[:category].id

    edit_podcast_path =
      Routes.moderation_frontend_path(socket, :edit_podcast, category_id, podcast_id)

    {:noreply, push_navigate(socket, to: edit_podcast_path)}
  end

  def handle_info({:show_in_frontend, podcast_id}, socket) do
    show_podcast_path = Routes.podcast_frontend_path(socket, :show, podcast_id)
    {:noreply, redirect(socket, to: show_podcast_path)}
  end

  def handle_info({:remove_from_moderation, podcast_id}, socket) do
    CategoryPodcast.delete(socket.assigns.category.id, podcast_id)

    socket =
      socket
      |> put_flash(:info, "Podcast removed from your moderation.")
      |> refresh_podcast_grid()

    {:noreply, socket}
  end

  def handle_event("add-feed", %{"url" => url}, socket) do
    category_id = socket.assigns.category.id

    socket =
      case Feed.clean_and_best_matching(url) do
        nil ->
          case Pan.Parser.RssFeed.initial_import(url) do
            {:ok, podcast_id} ->
              CategoryPodcast.get_or_insert(category_id, podcast_id)
              put_flash(socket, :info, "New podcast imported and added to your moderation.")

            {:error, error} ->
              put_flash(socket, :error, "Could not import that feed: #{error}")
          end

        feed ->
          podcast = Podcast.get_by_id(feed.podcast_id)
          CategoryPodcast.get_or_insert(category_id, podcast.id)

          case Pan.Parser.Podcast.update_from_feed(podcast) do
            {:ok, _message} ->
              Pan.Search.Podcast.update_index(podcast.id)
              Podcast.remove_unwanted_references(podcast.id)

              put_flash(
                socket,
                :info,
                "We already know that podcast and added it to your moderation."
              )

            {:error, message} ->
              put_flash(
                socket,
                :error,
                "Added to your moderation, but the refresh failed: #{message}"
              )
          end
      end

    {:noreply, refresh_podcast_grid(socket)}
  end

  def handle_event("search-existing-podcast", %{"term" => term}, socket) do
    results =
      if String.length(String.trim(term)) >= 2 do
        Podcast.search_by_title(term)
      else
        []
      end

    {:noreply, assign(socket, existing_search_term: term, existing_search_results: results)}
  end

  def handle_event("add-existing-podcast", %{"id" => id}, socket) do
    podcast_id = String.to_integer(id)
    CategoryPodcast.get_or_insert(socket.assigns.category.id, podcast_id)

    socket =
      socket
      |> put_flash(:info, "Podcast added to your moderation.")
      |> refresh_podcast_grid()

    {:noreply, socket}
  end

  defp refresh_podcast_grid(socket) do
    podcast_ids = Podcast.ids_by_category_id(socket.assigns.category.id)

    send_update(ModerationGrid,
      id: "moderation_table",
      search_filter: {:id, podcast_ids},
      records: []
    )

    assign(socket, podcast_ids: podcast_ids)
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      This is not one of your moderations
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-2xl">
        Moderating {@category.title}
      </h1>

      <form phx-submit="add-feed" class="my-4 flex gap-2 max-w-2xl">
        <input
          type="text"
          name="url"
          placeholder="Paste a podcast feed URL to add it to your moderation..."
          required
          class="flex-1 border border-gray rounded px-2 py-1"
        />
        <button type="submit" class="btn btn-primary btn-sm">Add feed</button>
      </form>

      <form phx-change="search-existing-podcast" class="my-4 max-w-2xl">
        <input
          type="text"
          name="term"
          value={@existing_search_term}
          placeholder="...or search for an existing Panoptikum podcast by title"
          phx-debounce="300"
          class="w-full border border-gray rounded px-2 py-1"
        />
      </form>

      <ul
        :if={@existing_search_results != []}
        class="my-4 max-w-2xl divide-y divide-gray border border-gray rounded"
      >
        <li
          :for={podcast <- @existing_search_results}
          class="flex items-center justify-between gap-2 px-2 py-1"
        >
          <span>{podcast.title}</span>
          <span :if={podcast.id in @podcast_ids} class="text-sm text-gray-dark">
            Already in your moderation
          </span>
          <button
            :if={podcast.id not in @podcast_ids}
            type="button"
            phx-click="add-existing-podcast"
            phx-value-id={podcast.id}
            class="btn btn-primary btn-sm"
          >
            ➕ Add
          </button>
        </li>
      </ul>

      <.live_component
        module={ModerationGrid}
        id="moderation_table"
        heading="Listing Podcasts"
        model={Podcast}
        cols={@cols}
        search_filter={{:id, @podcast_ids}}
        buttons={[
          :pagination,
          :show_in_frontend,
          :edit_podcast,
          :show_episodes,
          :show_feeds,
          :remove_from_moderation,
          :number_of_records,
          :search
        ]}
      />
    </div>
    """
  end
end
