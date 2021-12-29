defmodule PanWeb.Live.Episode.RecommendationList do
  use Surface.LiveComponent
  alias PanWeb.Live.Episode.RecommendForm
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  require Integer

  prop(current_user_id, :integer, required: true)
  prop(episode, :map, required: true)
  prop(changeset, :map, required: true)
  data(recommendations, :list, default: [])
  data(recommendations_count, :integer, default: 0)
  prop(page, :integer, default: 1)
  prop(per_page, :integer, default: 10)

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
    |> URI.encode_www_form
  end

  defp facebook(episode, recommendation) do
    episode.title <> "%0A" <> truncate_string(recommendation.comment, 220)
  end

  def render(assigns) do
    ~F"""
    <div class="my-4">
      {#if @episode.recommendations != [] or @current_user_id}
        <h2 class="text-2xl">Recommendations</h2>

        {#if @episode.recommendations != []}
          <p class="text-right">
            <a href="https://panoptikum.io/complaints"
              class="text-link hover-text-link-dark">Complain</a>
          </p>

          <table class="border border-separate border-gray-lighter">
            <thead>
              <tr>
                <th>User</th>
                <th>Recommendation</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody id="latest_recommendations" phx-update="append">
              {#for recommendation <- @episode.recommendations}
                <tr id={"recommendation-row-#{recommendation.id}"}>
                  <td>
                    <p :if={@current_user_id == recommendation.user_id} class="mb-2"><nobr>
                      <a href={"https://twitter.com/intent/tweet?text=#{social(@episode, recommendation)}&url=#{social_url(@episode)}"}
                        class="bg-aqua hover:bg-aqua-light px-3 py-2 my-4 rounded-full text-white" alt="tweet it">tweet</a>
                      <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@episode)}&quote=#{facebook(@episode, recommendation)}"},
                        class="bg-blue-jeans hover:bg-blue-jeans-light px-3 py-2 my-4 rounded-full text-white" alt="post on facebook">fb</a>
                      <a href={"mailto:?subject=#{social(@episode, recommendation)}&body=#{social_url(@episode)}"}
                        class="bg-grass bg-grass-light px-3 py-2 my-4 rounded-full text-white" alt="send an email">mail</a></nobr>
                    </p>
                    {recommendation.user.name}
                  </td>
                  <td>{recommendation.comment}</td>
                  <td align="right">
                    {recommendation.inserted_at |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
                  </td>
                </tr>
              {/for}
            </tbody>
          </table>
          <button :if={@page * @per_page < @recommendations_count}
                  :on-click="load-more"
                  class="border border-solid inline-block shadow m-4 py-1 px-2 rounded text-sm bg-info
                        hover:bg-info-light text-white border-gray-dark">
            Load more
          </button>
        {/if}

        <RecommendForm current_user_id={@current_user_id}
                       changeset={@changeset}
                       episode={@episode} />
      {/if}
    </div>
    """
  end
end
