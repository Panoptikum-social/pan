defmodule PanWeb.Live.Chapter.RecommendationList do
  use Surface.Component
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  prop(current_user_id, :integer, required: true)
  prop(chapter, :map, required: true)
  prop(episode, :map, required: true)

  def social(chapter, recommendation) do
    "👍 #{chapter.title}%0A💬 #{truncate_string(recommendation.comment, 220)}%0A🔊 "
  end

  def social_url(episode) do
    episode_frontend_url(Endpoint, :show, episode)
    |> URI.encode_www_form
  end

  defp facebook(chapter, recommendation) do
    chapter.title <> "%0A" <> truncate_string(recommendation.comment, 220)
  end

  def render(assigns) do
    ~F"""
    <div if={@chapter.recommendations != []}
          class="panel panel-info">
      <div class="panel-heading">
        Recommendations
        <span class="text-right">
          <a href="https://panoptikum.io/complaints"
             class="text-link hover-text-link-dark">Complain</a>
        </span>
      </div>
      <ul class="list-group">
        {#for recommendation <- @chapter.recommendations}
          <li class="list-group-item"
              id={"chapter-#{@chapter.id}"}>
              <p :if={@current_user_id == recommendation.user_id} class="mb-2"><nobr>
              <a href={"https://twitter.com/intent/tweet?text=#{social(@chapter, recommendation)}&url=#{social_url(@episode)}"}
                class="bg-aqua hover:bg-aqua-light px-3 py-2 my-4 rounded-full text-white" alt="tweet it">tweet</a>
              <a href={"https://www.facebook.com/sharer/sharer.php?u=#{social_url(@episode)}&quote=#{facebook(@chapter, recommendation)}"},
                class="bg-blue-jeans hover:bg-blue-jeans-light px-3 py-2 my-4 rounded-full text-white" alt="post on facebook">fb</a>
              <a href={"mailto:?subject=#{social(@chapter, recommendation)}&body=#{social_url(@episode)}"}
                class="bg-grass bg-grass-light px-3 py-2 my-4 rounded-full text-white" alt="send an email">mail</a></nobr>
            </p>

            <b>{recommendation.user.name}:</b> {recommendation.comment}
            <span class="pull-right">{ recommendation.inserted_at |> Timex.format!("{ISOdate} {h24}:{m}")}</span>
          </li>
        {/for}
      </ul>
    </div>
    """
  end
end
