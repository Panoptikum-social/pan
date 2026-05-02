defmodule PanWeb.Live.Podcast.RecommendationList do
  use PanWeb, :live_component
  alias PanWeb.Live.Podcast.RecommendForm
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  def mount(socket) do
    {:ok, assign(socket, recommendations_count: 0, page: 1, per_page: 10) |> stream(:recommendations, [])}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    recommendations =
      Recommendation.get_by_podcast_id(socket.assigns.podcast.id, socket.assigns.page, socket.assigns.per_page)

    recommendations_count = Recommendation.count_by_podcast_id(socket.assigns.podcast.id)

    socket =
      socket
      |> assign(recommendations_count: recommendations_count)
      |> stream(:recommendations, recommendations)

    {:ok, socket}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    page = assigns.page + 1
    recommendations = Recommendation.get_by_podcast_id(assigns.podcast.id, page, assigns.per_page)
    {:noreply, socket |> assign(page: page) |> stream(:recommendations, recommendations)}
  end

  def social(podcast, recommendation) do
    "👍 #{podcast.title}%0A💬 #{truncate_string(recommendation.comment, 220)}%0A🔊 "
  end

  def social_url(podcast) do
    podcast_frontend_url(Endpoint, :show, podcast)
    |> URI.encode_www_form()
  end

  defp facebook(podcast, recommendation) do
    podcast.title <> "%0A" <> truncate_string(recommendation.comment, 220)
  end

  attr :current_user_id, :integer, required: true
  attr :podcast, :map, required: true
  attr :changeset, :map, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 10

  def render(assigns) do
    ~H"""
    <div class="my-4">
      <div :if={@recommendations_count > 0} class="float-right">
        <a href="https://blog.panoptikum.social/complaints"
          class="text-link hover-text-link-dark">Complain</a>
      </div>
      <h2 id="recommendations" class="text-2xl">Recommendations</h2>
      <div :if={@recommendations_count > 0}>
        <table class="border border-separate border-gray-lighter mt-4 w-full">
          <thead>
            <tr>
              <th class="p-2">User</th>
              <th class="p-2">Recommendation</th>
              <th class="p-2">Date</th>
            </tr>
          </thead>
          <tbody id="latest_recommendations" phx-update="stream">
            <tr :for={{dom_id, recommendation} <- @streams.recommendations}
                id={dom_id}
                class="even:bg-gray-lighter">
              <td class="p-2">
                <p :if={@current_user_id == recommendation.user_id} class="mb-2"><nobr>
                  <a href={"https://twitter.com/intent/tweet?text=#{social(@podcast, recommendation)}&url=#{social_url(@podcast)}"}
                    class="bg-aqua hover:bg-aqua-light px-3 py-2 my-4 rounded-full text-white" alt="tweet it">tweet</a>
                  <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@podcast)}&quote=#{facebook(@podcast, recommendation)}"},
                    class="bg-blue-jeans hover:bg-blue-jeans-light px-3 py-2 my-4 rounded-full text-white" alt="post on facebook">fb</a>
                  <a href={"mailto:?subject=#{social(@podcast, recommendation)}&body=#{social_url(@podcast)}"}
                    class="bg-grass-light px-3 py-2 my-4 rounded-full text-white" alt="send an email">mail</a></nobr>
                </p>
                {recommendation.user.name}
              </td>
              <td class="p-2">{recommendation.comment}</td>
              <td class="p-2" align="right">
                {Calendar.strftime(recommendation.inserted_at, "%x")}
              </td>
            </tr>
          </tbody>
        </table>
        <button :if={@page * @per_page < @recommendations_count}
                phx-click="load-more"
                phx-target={@myself}
                class="btn btn-info btn-sm m-4">
          Load more
        </button>
      </div>

      <RecommendForm.render current_user_id={@current_user_id}
                   changeset={@changeset}
                   podcast={@podcast} />
    </div>
    """
  end
end
