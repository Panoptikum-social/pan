defmodule PanWeb.Live.Episode.RecommendationList do
  use PanWeb, :live_component
  alias PanWeb.Live.Episode.RecommendForm
  alias PanWeb.Component.UserButton
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

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

  attr :current_user_id, :integer, required: true
  attr :episode, :map, required: true
  attr :changeset, :map, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 10

  def render(assigns) do
    ~H"""
    <div class="mt-4 max-w-4xl">
      <div :if={@episode.recommendations != [] or @current_user_id}>
        <div :if={@episode.recommendations != []} class="float-right">
          <a
            href="https://blog.panoptikum.social/complaints"
            class="underline hover:text-primary"
          >Complain</a>
        </div>

        <h2 class="text-2xl">Recommendations</h2>

        <div :if={@episode.recommendations != []}>
          <table class="table table-sm table-zebra mt-4">
            <thead>
              <tr>
                <th>User</th>
                <th>Recommendation</th>
                <th class="text-right">Date</th>
              </tr>
            </thead>
            <tbody id="latest_recommendations">
              <tr
                :for={recommendation <- @episode.recommendations}
                id={"recommendation-row-#{recommendation.id}"}
              >
                <td class="align-top whitespace-nowrap">
                  <UserButton.render for={recommendation.user} />
                  <div :if={@current_user_id == recommendation.user_id} class="mt-1 flex gap-1">
                    <a
                      href={"https://twitter.com/intent/tweet?text=#{social(@episode, recommendation)}&url=#{social_url(@episode)}"}
                      class="btn btn-outline btn-info btn-xs"
                      alt="tweet it"
                    >tweet</a>
                    <a
                      href={"mailto:?subject=#{social(@episode, recommendation)}&body=#{social_url(@episode)}"}
                      class="btn btn-outline btn-success btn-xs"
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
          episode={@episode}
        />
      </div>
    </div>
    """
  end
end
