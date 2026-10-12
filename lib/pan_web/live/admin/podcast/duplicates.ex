defmodule PanWeb.Live.Admin.Podcast.Duplicates do
  use PanWeb, :admin_live_view
  alias PanWeb.{Endpoint, PodcastDuplicates}
  import PanWeb.Router.Helpers

  # The alternate feed check finds well over a thousand pairs, mostly old
  # redirect targets; rendering all of them would only bury the rest.
  @max_rows 200

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Duplicate podcasts", max_rows: @max_rows)
     |> assign_async(:marked, fn -> {:ok, %{marked: PodcastDuplicates.marked_by_updater()}} end)
     |> assign_async(:same_feed_url, fn ->
       {:ok, %{same_feed_url: PodcastDuplicates.same_feed_url()}}
     end)
     |> assign_async(:same_title, fn -> {:ok, %{same_title: PodcastDuplicates.same_title()}} end)
     |> assign_async(:feed_url_is_alternate, fn ->
       {:ok, %{feed_url_is_alternate: PodcastDuplicates.feed_url_is_alternate()}}
     end)}
  end

  attr :podcast, :map, required: true

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
      </div>
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
      <.podcast_cell :for={podcast <- @podcasts} podcast={podcast} />
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :result, :map, required: true
  attr :max_rows, :integer, required: true
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section class="mt-8">
      <h2 class="text-xl font-bold">
        {@title}
        <span :if={@result.ok?} class="font-normal">({length(@result.result)})</span>
      </h2>
      <p class="text-sm text-gray-dark max-w-3xl">{@description}</p>
      <p :if={@result.loading} class="mt-2">Loading ...</p>
      <p :if={@result.failed} class="mt-2 text-danger">Could not be loaded.</p>
      <p :if={@result.ok? and @result.result == []} class="mt-2">Nothing found.</p>
      <p :if={@result.ok? and length(@result.result) > @max_rows} class="mt-2 text-sm">
        Showing the first {@max_rows}.
      </p>
      {render_slot(@inner_block)}
    </section>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <h1 class="text-3xl">Duplicate podcasts</h1>
      <p class="max-w-3xl">
        Since a podcast is identified by its feed URL only, double imports and format feeds
        (mp3/ogg of one show) end up as separate podcasts. Each check is listed on its own.
      </p>

      <.section
        title="Feed delivers a different show"
        description="Marked by the episode updater: the feed redirects to, or announces, a feed with a new title and mostly unknown episodes (not followed, the new feed is in the feed backlog), or the result was unclear and needs a review (an email went out)."
        result={@marked}
        max_rows={@max_rows}
      >
        <table
          :if={@marked.ok? and @marked.result != []}
          class="table table-zebra table-xs my-4 w-auto"
        >
          <tbody>
            <tr :for={podcast <- Enum.take(@marked.result, @max_rows)}>
              <td><.podcast_cell podcast={podcast} /></td>
              <td class="max-w-xl">{podcast.last_error_message}</td>
            </tr>
          </tbody>
        </table>
      </.section>

      <.section
        title="Same feed URL"
        description="Several podcasts with the same feed URL: a double import, or an old feed redirected to its successor."
        result={@same_feed_url}
        max_rows={@max_rows}
      >
        <table
          :if={@same_feed_url.ok? and @same_feed_url.result != []}
          class="table table-zebra table-xs my-4 w-auto"
        >
          <tbody>
            <tr :for={{url, podcasts} <- Enum.take(@same_feed_url.result, @max_rows)}>
              <td><.group key={url} podcasts={podcasts} /></td>
            </tr>
          </tbody>
        </table>
      </.section>

      <.section
        title="Same title"
        description="Several podcasts with the same title. Often different shows (that's fine), sometimes format feeds of one show or a double import."
        result={@same_title}
        max_rows={@max_rows}
      >
        <table
          :if={@same_title.ok? and @same_title.result != []}
          class="table table-zebra table-xs my-4 w-auto"
        >
          <tbody>
            <tr :for={{title, podcasts} <- Enum.take(@same_title.result, @max_rows)}>
              <td><.group key={title} podcasts={podcasts} /></td>
            </tr>
          </tbody>
        </table>
      </.section>

      <.section
        title="Feed URL is another podcast's alternate feed"
        description="One podcast's feed URL is listed as an alternate feed (e.g. an old URL before a redirect) of another podcast."
        result={@feed_url_is_alternate}
        max_rows={@max_rows}
      >
        <table
          :if={@feed_url_is_alternate.ok? and @feed_url_is_alternate.result != []}
          class="table table-zebra table-xs my-4 w-auto"
        >
          <tbody>
            <tr :for={{_url, podcasts} <- Enum.take(@feed_url_is_alternate.result, @max_rows)}>
              <td :for={podcast <- podcasts}><.podcast_cell podcast={podcast} /></td>
            </tr>
          </tbody>
        </table>
      </.section>
    </div>
    """
  end
end
