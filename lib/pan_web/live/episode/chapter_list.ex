defmodule PanWeb.Live.Episode.ChapterList do
  use PanWeb, :html
  alias PanWeb.Component.LikeButton
  alias PanWeb.Live.Chapter.{RecommendForm, RecommendationList}

  attr :current_user_id, :integer, required: true
  attr :changeset, :map, required: true
  attr :episode, :map, required: true

  def render(assigns) do
    ~H"""
    <div :if={@episode.chapters != []} class="my-4">
      <h3 class="text-xl" id="chapters">Deeplinks to Chapters</h3>

      <div class="grid grid-cols-3 gap-2">
        <h4 :if={@current_user_id} class="text-lg col-start-2 col-span-2">Your recommendation:</h4>

        <%= for chapter <- @episode.chapters do %>
          <div>
            <a href="javascript:void(0)"
               rel="podlove-web-player"
               data-ref="podlove-player"
               data-action="play"
               data-time={chapter.start}
               class="text-link hover:text-link-dark">{chapter.start}</a>
            {chapter.title}
            <br :if={@current_user_id} />
            <LikeButton.render :if={@current_user_id}
                        id={"chapter_#{chapter.id}_like_button"}
                        current_user_id={@current_user_id}
                        model={PanWeb.Chapter}
                        instance={chapter} />
          </div>

          <.live_component module={RecommendForm}
                           id={"recommend-form-#{chapter.id}"}
                           current_user_id={@current_user_id}
                           changeset={@changeset}
                           chapter={chapter} />

          <RecommendationList.render current_user_id={@current_user_id}
                                     chapter={chapter}
                                     episode={@episode} />
        <% end %>
      </div>
    </div>
    """
  end
end
