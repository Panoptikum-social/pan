defmodule PanWeb.Live.Podcast.RecommendationList do
  use Surface.LiveComponent
  alias PanWeb.Live.Podcast.RecommendForm
  alias PanWeb.{Endpoint, Recommendation}
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  require Integer

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  prop(changeset, :map, required: true)
  data(recommendations, :list, default: [])
  data(recommendations_count, :integer, default: 0)
  prop(page, :integer, default: 1)
  prop(per_page, :integer, default: 10)

  def update(assigns, socket) do
    recommendations =
      Recommendation.get_by_podcast_id(assigns.podcast.id, assigns.page, assigns.per_page)

    recommendations_count = Recommendation.count_by_podcast_id(assigns.podcast.id)

    socket =
      assign(socket, assigns)
      |> assign(recommendations: recommendations)
      |> assign(recommendations_count: recommendations_count)

    {:ok, socket}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  defp fetch(%{assigns: %{podcast: podcast, page: page, per_page: per_page}} = socket) do
    assign(socket, recommendations: Recommendation.get_by_podcast_id(podcast.id, page, per_page))
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

  def render(assigns) do
    ~F"""
    <div class="my-4">
      <div :if={@recommendations != []}
           class="float-right">
        <a href="https://panoptikum.io/complaints"
          class="text-link hover-text-link-dark">Complain</a>
      </div>
      <h2 id="recommendations" class="text-2xl">Recommendations</h2>
      {#if @recommendations != []}
        <table class="border border-separate border-gray-lighter mt-4">
          <thead>
            <tr>
              <th class="p-2">User</th>
              <th class="p-2">Recommendation</th>
              <th class="p-2">Date</th>
            </tr>
          </thead>
          <tbody id="latest_recommendations" phx-update="append">
            {#for {recommendation, index} <- @recommendations |> Enum.with_index}
              <tr id={"recommendation-row-#{recommendation.id}"}>
                <td class={"p-2",
                          "bg-gray-lighter": Integer.is_even(index)}>
                  <p :if={@current_user_id == recommendation.user_id} class="mb-2"><nobr>
                    <a href={"https://twitter.com/intent/tweet?text=#{social(@podcast, recommendation)}&url=#{social_url(@podcast)}"}
                      class="bg-aqua hover:bg-aqua-light px-3 py-2 my-4 rounded-full text-white" alt="tweet it">tweet</a>
                    <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@podcast)}&quote=#{facebook(@podcast, recommendation)}"},
                      class="bg-blue-jeans hover:bg-blue-jeans-light px-3 py-2 my-4 rounded-full text-white" alt="post on facebook">fb</a>
                    <a href={"mailto:?subject=#{social(@podcast, recommendation)}&body=#{social_url(@podcast)}"}
                      class="bg-grass bg-grass-light px-3 py-2 my-4 rounded-full text-white" alt="send an email">mail</a></nobr>
                  </p>
                  {recommendation.user.name}
                </td>
                <td class={"p-2",
                          "bg-gray-lighter": Integer.is_even(index)}>{recommendation.comment}</td>
                <td  class={"p-2",
                            "bg-gray-lighter": Integer.is_even(index)}
                    align="right">
                  {Calendar.strftime(recommendation.inserted_at, "%x")}
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
                     podcast={@podcast} />
    </div>
    """
  end
end
