defmodule PanWeb.Live.Episode.RecommendationList do
  use PanWeb, :live_component
  alias PanWeb.Live.Episode.RecommendForm
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  require Integer

  def mount(socket) do
    {:ok, assign(socket, recommendations: [], recommendations_count: 0)}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  defp fetch(%{assigns: %{episode: episode, page: page, per_page: per_page}} = socket) do
    assign(socket, recommendations: Recommendation.get_by_episode_id(episode.id, page, per_page))
  end

  def social(episode, recommendation) do
    "👍 #{episode.title}%0A💬 #{truncate_string(recommendation.comment, 220)}%0A🔊 "
  end

  def social_url(episode) do
    episode_frontend_url(Endpoint, :show, episode)
    |> URI.encode_www_form()
  end

  defp facebook(episode, recommendation) do
    episode.title <> "%0A" <> truncate_string(recommendation.comment, 220)
  end

  attr :current_user_id, :integer, required: true
  attr :episode, :map, required: true
  attr :changeset, :map, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 10

  def render(assigns) do
    ~H"""
    <div class="mt-4">
      <div :if={@episode.recommendations != [] or @current_user_id}>
        <div :if={@episode.recommendations != []} class="float-right">
          <a href="https://blog.panoptikum.social/complaints"
            class="text-link hover-text-link-dark">Complain</a>
        </div>

        <h2 class="text-2xl">Recommendations</h2>

        <div :if={@episode.recommendations != []}>
          <table class="border border-separate border-gray-lighter">
            <thead>
              <tr>
                <th>User</th>
                <th>Recommendation</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody id="latest_recommendations">
              <tr :for={recommendation <- @episode.recommendations}
                  id={"recommendation-row-#{recommendation.id}"}>
                <td>
                  <p :if={@current_user_id == recommendation.user_id} class="mb-2"><nobr>
                    <a href={"https://twitter.com/intent/tweet?text=#{social(@episode, recommendation)}&url=#{social_url(@episode)}"}
                      class="bg-aqua hover:bg-aqua-light px-2 py-1 my-4 rounded-xl text-white" alt="tweet it">tweet</a>
                    <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@episode)}&quote=#{facebook(@episode, recommendation)}"},
                      class="bg-blue-jeans hover:bg-blue-jeans-light px-2 py-1 my-4 rounded-xl text-white" alt="post on facebook">fb</a>
                    <a href={"mailto:?subject=#{social(@episode, recommendation)}&body=#{social_url(@episode)}"}
                      class="bg-grass-light px-2 py-1 my-4 rounded-xl text-white" alt="send an email">mail</a></nobr>
                  </p>
                  {recommendation.user.name}
                </td>
                <td>{recommendation.comment}</td>
                <td align="right">
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
                     episode={@episode} />
      </div>
    </div>
    """
  end
end
