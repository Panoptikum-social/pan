defmodule PanWeb.Live.Chapter.RecommendationList do
  use PanWeb, :html
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers
  import PanWeb.ViewHelpers, only: [truncate_string: 2]

  def social(chapter, recommendation) do
    "👍 #{chapter.title}%0A💬 #{truncate_string(recommendation.comment, 220)}%0A🔊 "
  end

  def social_url(episode) do
    episode_frontend_url(Endpoint, :show, episode)
    |> URI.encode_www_form()
  end

  attr :current_user_id, :integer, required: true
  attr :chapter, :map, required: true
  attr :episode, :map, required: true

  def render(assigns) do
    ~H"""
    <div :if={@chapter.recommendations != []} class="my-4 col-span-3">
      <div class="float-right">
        <a
          href="https://blog.panoptikum.social/complaints"
          class="underline hover:text-primary"
        >Complain</a>
      </div>

      <h3 class="text-xl">Recommendations</h3>
      <ul class="my-4 bg-base-100">
        <li
          :for={recommendation <- @chapter.recommendations}
          id={"chapter-#{@chapter.id}"}
        >
          <p :if={@current_user_id == recommendation.user_id} class="mt-4">
            <nobr>
              <a
                href={"https://twitter.com/intent/tweet?text=#{social(@chapter, recommendation)}&url=#{social_url(@episode)}"}
                class="btn btn-outline btn-info btn-xs"
                alt="tweet it"
              >tweet</a>
              <a
                href={"mailto:?subject=#{social(@chapter, recommendation)}&body=#{social_url(@episode)}"}
                class="btn btn-outline btn-success btn-xs"
                alt="send an email"
              >mail</a>
            </nobr>
          </p>

          <b>{recommendation.user.name}:</b> {recommendation.comment}
          <span class="float-right text-sm text-base-content/70">{Calendar.strftime(
            recommendation.inserted_at,
            "%x %H:%M"
          )}</span>
        </li>
      </ul>
    </div>
    """
  end
end
