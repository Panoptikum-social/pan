defmodule PanWeb.Live.Podcast.RecommendationList do
  use PanWeb, :live_component
  alias PanWeb.Live.Podcast.RecommendForm
  alias PanWeb.Component.UserButton
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  def mount(socket) do
    {:ok,
     assign(socket, recommendations_count: 0, page: 1, per_page: 10)
     |> stream(:recommendations, [])}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    recommendations =
      Recommendation.get_by_podcast_id(
        socket.assigns.podcast.id,
        socket.assigns.page,
        socket.assigns.per_page
      )

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

  attr :current_user_id, :integer, required: true
  attr :podcast, :map, required: true
  attr :changeset, :map, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 10

  def render(assigns) do
    ~H"""
    <div class="my-4 max-w-4xl">
      <div :if={@recommendations_count > 0} class="float-right">
        <a
          href="https://blog.panoptikum.social/complaints"
          class="underline hover:text-primary"
        >Complain</a>
      </div>
      <h2 id="recommendations" class="text-2xl">Recommendations</h2>
      <div :if={@recommendations_count > 0}>
        <table class="table table-sm table-zebra mt-4">
          <thead>
            <tr>
              <th>User</th>
              <th>Recommendation</th>
              <th class="text-right">Date</th>
            </tr>
          </thead>
          <tbody id="latest_recommendations" phx-update="stream">
            <tr :for={{dom_id, recommendation} <- @streams.recommendations} id={dom_id}>
              <td class="align-top whitespace-nowrap">
                <UserButton.render for={recommendation.user} />
                <div :if={@current_user_id == recommendation.user_id} class="mt-1 flex gap-1">
                  <a
                    href={"https://twitter.com/intent/tweet?text=#{social(@podcast, recommendation)}&url=#{social_url(@podcast)}"}
                    class="btn btn-soft btn-info btn-xs"
                    alt="tweet it"
                  >tweet</a>
                  <a
                    href={"mailto:?subject=#{social(@podcast, recommendation)}&body=#{social_url(@podcast)}"}
                    class="btn btn-soft btn-success btn-xs"
                    alt="send an email"
                  >mail</a>
                </div>
              </td>
              <td class="align-top">{recommendation.comment}</td>
              <td class="align-top text-right whitespace-nowrap">
                {Calendar.strftime(recommendation.inserted_at, "%x")}
              </td>
            </tr>
          </tbody>
        </table>
        <button
          :if={@page * @per_page < @recommendations_count}
          phx-click="load-more"
          phx-target={@myself}
          class="btn btn-outline btn-info btn-sm m-4"
        >
          Load more
        </button>
      </div>

      <RecommendForm.render
        current_user_id={@current_user_id}
        changeset={@changeset}
        podcast={@podcast}
      />
    </div>
    """
  end
end
