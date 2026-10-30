defmodule PanWeb.Live.Moderation.ApiErrors do
  use PanWeb, :moderation_live_view
  on_mount PanWeb.Live.AssignUserAndAdmin
  alias PanWeb.{ApiRequestError, Category, CategoryPodcast, Community, Moderation}
  alias PanWeb.Router.Helpers, as: Routes

  # :id is the community slug, as on the other moderation pages
  def mount(%{"id" => slug}, session, socket) do
    community = Community.get_by_slug(slug)

    if community &&
         (Moderation.get_by_community_slug_and_user_id(slug, session["user_id"]) ||
            socket.assigns.admin) do
      {:ok,
       assign(socket,
         community: community,
         category: Category.get_by_id(community.category_id),
         errors: ApiRequestError.last_day_by_podcast(community.category_id)
       )}
    else
      {:ok, assign(socket, error: "not_found")}
    end
  end

  def handle_event("reload", _params, socket) do
    {:noreply,
     assign(socket, errors: ApiRequestError.last_day_by_podcast(socket.assigns.category.id))}
  end

  # only out of the community: moderators don't delete podcasts
  def handle_event("remove", %{"podcast_id" => podcast_id}, socket) do
    category = socket.assigns.category
    CategoryPodcast.delete(category.id, String.to_integer(podcast_id))

    {:noreply,
     socket
     |> put_flash(:info, "Podcast #{podcast_id} removed from #{category.title}.")
     |> assign(errors: ApiRequestError.last_day_by_podcast(category.id))}
  end

  defp vienna_string(naive_date_time) do
    naive_date_time
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Vienna")
    |> Calendar.strftime("%d.%m.%Y %H:%M")
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
        API errors in {@category.title}
      </h1>

      <p class="my-4 max-w-3xl">
        Failed API requests of the last 24 hours on podcasts of this community and on podcasts
        that no longer exist, one row per podcast with its latest error. Times are Vienna time.
        <.link
          navigate={Routes.moderation_frontend_path(@socket, :moderation, @community)}
          class="link"
        >Back to the moderation</.link>
      </p>

      <button type="button" phx-click="reload" class="btn btn-outline btn-primary btn-sm">Reload</button>

      <p :if={@errors == []} class="my-4">No failed API requests in the last 24 hours.</p>

      <div :if={@errors != []} class="my-4 overflow-x-auto">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Podcast</th>
              <th></th>
              <th>Error</th>
              <th>Status</th>
              <th>Failed</th>
              <th>Last failure</th>
              <th>Endpoints</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={error <- @errors}>
              <td>
                <.link
                  :if={error.podcast_title}
                  navigate={
                    Routes.moderation_frontend_path(
                      @socket,
                      :edit_podcast,
                      @community,
                      error.podcast_id
                    )
                  }
                  class="link"
                >{error.podcast_title}</.link>
                <span :if={!error.podcast_title && error.former} class="italic">
                  {error.former.title}
                </span>
                <span :if={!error.podcast_title && !error.former} class="italic">
                  no longer exists
                </span>
                <span class="text-sm">(ID {error.podcast_id})</span>
              </td>
              <td>
                <div class="flex gap-1 whitespace-nowrap">
                  <.link
                    :if={error.feed_id}
                    href={
                      Routes.moderation_frontend_path(
                        @socket,
                        :edit_feed,
                        @community,
                        error.feed_id
                      )
                    }
                    target="_blank"
                    class="btn btn-outline btn-primary btn-xs"
                  >Fix feed</.link>
                  <button
                    :if={error.podcast_title}
                    type="button"
                    phx-click="remove"
                    phx-value-podcast_id={error.podcast_id}
                    data-confirm={"Remove \"#{error.podcast_title}\" from #{@category.title}? The podcast stays on Panoptikum."}
                    class="btn btn-outline btn-warning btn-xs"
                  >
                    Remove from community
                  </button>
                </div>
              </td>
              <td class="max-w-xl">
                <span class="font-semibold">{error.latest.title}</span>
                <span :if={error.latest.detail}>{error.latest.detail}</span>
              </td>
              <td>{error.latest.status}</td>
              <td>{error.count}×</td>
              <td class="whitespace-nowrap">{vienna_string(error.latest.inserted_at)}</td>
              <td class="text-sm">{Enum.join(error.endpoints, ", ")}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
