defmodule PanWeb.Live.Podcast.RecommendationsList do
  use Surface.Component
  alias PanWeb.Live.Podcast.RecommendForm
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]
  require Integer

  prop(current_user_id, :integer, required: true)
  prop(podcast, :map, required: true)
  prop(changeset, :map, required: true)
  prop(recommendations, :list, required: true)

  def social(podcast, recommendation) do
    "👍 #{podcast.title}%0A💬 #{truncate_string(recommendation.comment, 220)}%0A🔊 "
  end

  def social_url(podcast) do
    URI.encode_www_form(podcast_frontend_url(Endpoint, :show, podcast))
  end

  defp facebook(podcast, recommendation) do
    podcast.title <> "%0A" <> truncate_string(recommendation.comment, 220)
  end

  def render(assigns) do
    ~F"""
    <h2 id="recommendations" class="text-2xl">Recommendations</h2>

    {#if @recommendations != []}
      <p class="text-right">
        <a href="https://panoptikum.io/complaints"
           class="text-link hover-text-link-dark">Complain</a>
      </p>

      <table class="border border-separate border-gray-lighter">
        <thead>
          <tr>
            <th class="p-2">User</th>
            <th class="p-2">Recommendation</th>
            <th class="p-2">Date</th>
          </tr>
        </thead>
        <tbody>
          {#for {recommendation, index} <- @recommendations |> Enum.with_index}
            <tr>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}>
                {#if @current_user_id == recommendation.user_id}
                  <p class="mb-2"><nobr>
                    <a href={"https://twitter.com/intent/tweet?text=#{social(@podcast, recommendation)}&url=#{social_url(@podcast)}"}
                       class="bg-aqua hover:bg-aqua-light px-3 py-2 my-4 rounded-full text-white" alt="tweet it">tweet</a>
                    <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@podcast)}&quote=#{facebook(@podcast, recommendation)}"},
                       class="bg-blue-jeans hover:bg-blue-jeans-light px-3 py-2 my-4 rounded-full text-white" alt="post on facebook">fb</a>
                    <a href={"mailto:?subject=#{social(@podcast, recommendation)}&body=#{social_url(@podcast)}"}
                       class="bg-grass bg-grass-light px-3 py-2 my-4 rounded-full text-white" alt="send an email">mail</a></nobr>
                  </p>
                {/if}
                {recommendation.user.name}
              </td>
              <td class={"p-2",
                         "bg-gray-lighter": Integer.is_even(index)}>{recommendation.comment}</td>
              <td  class={"p-2",
                          "bg-gray-lighter": Integer.is_even(index)}
                   align="right">
                {recommendation.inserted_at |> Timex.to_date |> Timex.format!("%e.%m.%Y", :strftime)}
              </td>
            </tr>
          {/for}
        </tbody>
      </table>
    {/if}

    <RecommendForm current_user_id={@current_user_id}
                   changeset={@changeset}
                   podcast={@podcast} />
    """
  end
end
