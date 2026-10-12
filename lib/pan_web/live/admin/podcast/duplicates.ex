defmodule PanWeb.Live.Admin.Podcast.Duplicates do
  use PanWeb, :admin_live_view
  alias Pan.Repo
  alias PanWeb.{Endpoint, Feed, Podcast, PodcastDuplicates, PodcastMerge}
  import PanWeb.Router.Helpers

  # The alternate feed check finds well over a thousand pairs, mostly old
  # redirect targets; rendering all of them would only bury the rest.
  @max_rows 200

  # {key, tab label, heading, description}; one check per tab, only the
  # active one is loaded
  @tabs [
    {"different_show", "Different show", "Feed delivers a different show",
     "Marked by the episode updater: the feed redirects to, or announces, a feed with a new title and mostly unknown episodes (not followed, the new feed is in the feed backlog), or the result was unclear and needs a review (an email went out)."},
    {"same_feed_url", "Same feed URL", "Same feed URL",
     "Several podcasts with the same feed URL: a double import, or an old feed redirected to its successor."},
    {"same_title", "Same title", "Same title",
     "Several podcasts with the same title. Often different shows (that's fine), sometimes format feeds of one show or a double import."},
    {"alternate", "Alternate feed", "Feed URL is another podcast's alternate feed",
     "One podcast's feed URL is listed as an alternate feed (e.g. an old URL before a redirect) of another podcast."}
  ]
  @tab_keys Enum.map(@tabs, &elem(&1, 0))

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Duplicate podcasts", max_rows: @max_rows, tabs: @tabs)}
  end

  def handle_params(params, _uri, socket) do
    tab = if params["tab"] in @tab_keys, do: params["tab"], else: hd(@tab_keys)
    {:noreply, socket |> assign(tab: tab) |> load()}
  end

  # also after every action, so the list shows the new state
  defp load(%{assigns: %{tab: tab}} = socket) do
    assign_async(socket, :candidates, fn -> {:ok, %{candidates: candidates(tab)}} end)
  end

  defp candidates("different_show"), do: PodcastDuplicates.marked_by_updater()
  defp candidates("same_feed_url"), do: PodcastDuplicates.same_feed_url()
  defp candidates("same_title"), do: PodcastDuplicates.same_title()
  defp candidates("alternate"), do: PodcastDuplicates.feed_url_is_alternate()

  def handle_event("retire", %{"id" => id}, socket) do
    podcast = Repo.get!(Podcast, id)

    socket =
      case Podcast.retire(podcast) do
        {:ok, _podcast} -> put_flash(socket, :info, "Podcast #{id} \"#{podcast.title}\" retired.")
        {:error, _changeset} -> put_flash(socket, :error, "Podcast #{id} could not be retired.")
      end

    {:noreply, load(socket)}
  end

  def handle_event("restore", %{"feed_id" => feed_id, "url" => url}, socket) do
    feed = Repo.get!(Feed, feed_id)

    socket =
      case Feed.restore_alternate(feed, url) do
        {:ok, _feed} ->
          put_flash(
            socket,
            :info,
            "Podcast #{feed.podcast_id}: feed URL is #{url} again, the next update shows whether it works."
          )

        {:error, message} when is_binary(message) ->
          put_flash(socket, :error, message)

        {:error, _changeset} ->
          put_flash(
            socket,
            :error,
            "The feed URL of podcast #{feed.podcast_id} could not be restored."
          )
      end

    {:noreply, load(socket)}
  end

  def handle_event("merge", %{"from_id" => from_id, "to_id" => to_id}, socket) do
    socket =
      case PodcastMerge.merge(String.to_integer(from_id), String.to_integer(to_id)) do
        {:ok, message} -> put_flash(socket, :info, message)
        {:error, message} -> put_flash(socket, :error, message)
      end

    {:noreply, load(socket)}
  end

  attr :podcast, :map, required: true
  # the other podcasts of the same group, offered as merge targets
  attr :merge_targets, :list, default: []

  defp podcast_cell(assigns) do
    ~H"""
    <div>
      <.link
        navigate={databrowser_path(Endpoint, :show, "podcast", @podcast.id)}
        class="text-link hover:text-link-dark"
      >
        {@podcast.id}
      </.link>
      <.link
        navigate={podcast_frontend_path(Endpoint, :show, @podcast.id)}
        class="text-link hover:text-link-dark"
      >
        {@podcast.title}
      </.link>
      <span class="text-sm text-gray-dark">
        {@podcast.episodes_count || 0} episodes
        <span :if={@podcast.retired} class="badge badge-warning badge-sm">retired</span>
      </span>
      <div :for={feed <- @podcast.feeds} class="text-xs text-gray-dark break-all">
        {feed.self_link_url}
        <form
          :if={feed.alternate_feeds != []}
          phx-submit="restore"
          class="mt-1 flex gap-1 items-center"
        >
          <input type="hidden" name="feed_id" value={feed.id} />
          <select name="url" class="select select-xs max-w-md">
            <option :for={alternate <- feed.alternate_feeds} value={alternate.url}>
              {Calendar.strftime(alternate.inserted_at, "%Y-%m-%d")} {alternate.url}
            </option>
          </select>
          <button type="submit" class="btn btn-info btn-xs">Restore previous</button>
        </form>
      </div>
      <form :if={@merge_targets != []} phx-submit="merge" class="mt-1 flex gap-1 items-center">
        <input type="hidden" name="from_id" value={@podcast.id} />
        <select name="to_id" class="select select-xs max-w-md">
          <option :for={target <- @merge_targets} value={target.id}>
            {target.id} {target.title}
          </option>
        </select>
        <button
          type="submit"
          data-confirm={"Merge podcast #{@podcast.id} \"#{@podcast.title}\" into the selected podcast? Podcast #{@podcast.id} is deleted afterwards."}
          class="btn btn-error btn-xs"
        >
          Merge into
        </button>
      </form>
      <button
        :if={!@podcast.retired}
        phx-click="retire"
        phx-value-id={@podcast.id}
        data-confirm={"Retire podcast #{@podcast.id} \"#{@podcast.title}\"?"}
        class="mt-1 btn btn-warning btn-xs"
      >
        Retire
      </button>
    </div>
    """
  end

  # Side by side up to 3 podcasts, one below the other for bigger groups,
  # which would otherwise be squeezed into unreadably narrow columns.
  @max_side_by_side 3

  attr :key, :string, required: true
  attr :podcasts, :list, required: true

  defp group(assigns) do
    assigns = assign(assigns, :side_by_side?, length(assigns.podcasts) <= @max_side_by_side)

    ~H"""
    <div class="text-sm font-semibold break-all">
      {@key} <span class="font-normal text-gray-dark">({length(@podcasts)})</span>
    </div>
    <div class={["mt-1", if(@side_by_side?, do: "flex gap-6", else: "flex flex-col gap-2")]}>
      <.podcast_cell
        :for={podcast <- @podcasts}
        podcast={podcast}
        merge_targets={Enum.reject(@podcasts, &(&1.id == podcast.id))}
      />
    </div>
    """
  end

  attr :tab, :string, required: true
  attr :candidates, :list, required: true

  defp rows(%{tab: "different_show"} = assigns) do
    ~H"""
    <tr :for={podcast <- @candidates}>
      <td><.podcast_cell podcast={podcast} /></td>
      <td class="max-w-xl">{podcast.last_error_message}</td>
    </tr>
    """
  end

  defp rows(%{tab: "alternate"} = assigns) do
    ~H"""
    <tr :for={{_url, podcasts} <- @candidates}>
      <td :for={podcast <- podcasts}>
        <.podcast_cell
          podcast={podcast}
          merge_targets={Enum.reject(podcasts, &(&1.id == podcast.id))}
        />
      </td>
    </tr>
    """
  end

  # same feed URL, same title: groups
  defp rows(assigns) do
    ~H"""
    <tr :for={{key, podcasts} <- @candidates}>
      <td><.group key={key} podcasts={podcasts} /></td>
    </tr>
    """
  end

  def render(assigns) do
    {_key, _label, heading, description} = List.keyfind(@tabs, assigns.tab, 0)
    assigns = assign(assigns, heading: heading, description: description)

    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Duplicate podcasts</h1>
      <p class="max-w-3xl">
        Since a podcast is identified by its feed URL only, double imports and format feeds
        (mp3/ogg of one show) end up as separate podcasts. Each check has its own tab.
      </p>

      <div role="tablist" class="tabs tabs-border mt-4">
        <.link
          :for={{key, label, _heading, _description} <- @tabs}
          patch={podcast_path(Endpoint, :duplicates, tab: key)}
          role="tab"
          class={["tab", key == @tab && "tab-active"]}
        >
          {label}
        </.link>
      </div>

      <section class="mt-4">
        <h2 class="text-xl font-bold">
          {@heading}
          <span :if={@candidates.ok?} class="font-normal">({length(@candidates.result)})</span>
        </h2>
        <p class="text-sm text-gray-dark max-w-3xl">{@description}</p>
        <p :if={@candidates.loading} class="mt-2">Loading ...</p>
        <p :if={@candidates.failed} class="mt-2 text-danger">Could not be loaded.</p>
        <p :if={@candidates.ok? and @candidates.result == []} class="mt-2">Nothing found.</p>
        <p :if={@candidates.ok? and length(@candidates.result) > @max_rows} class="mt-2 text-sm">
          Showing the first {@max_rows}.
        </p>
        <table
          :if={@candidates.ok? and @candidates.result != []}
          class="table table-zebra table-xs my-4 w-auto"
        >
          <tbody>
            <.rows tab={@tab} candidates={Enum.take(@candidates.result, @max_rows)} />
          </tbody>
        </table>
      </section>
    </div>
    """
  end
end
