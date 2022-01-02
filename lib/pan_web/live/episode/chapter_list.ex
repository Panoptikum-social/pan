defmodule PanWeb.Live.Episode.ChapterList do
  use Surface.Component
  alias PanWeb.Live.Chapter.{LikeButton, RecommendForm, RecommendationList}

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(episode, :map, required: true)

  def render(assigns) do
    ~F"""
    <div :if={@episode.chapters != []}
          class="my-4">
      <h3 class="text-xl"
          id="chapters">Deeplinks to Chapters</h3>

      <div class="grid grid-cols-3 gap-2">
        <h4 :if={@current_user_id}
            class="text-lg col-start-2 col-span-2">Your recommendation:</h4>

        {#for chapter <- @episode.chapters}
          <div>
            <a href="javascript:void(0)"
               rel="podlove-web-player"
               data-ref="podlove-player"
               data-action="play"
               data-time={chapter.start}
               class="text-link hover:text-link-dark">{chapter.start}</a>
            {chapter.title}
            <br :if={@current_user_id} />
            <LikeButton :if={@current_user_id}
                        id={"chapter_#{chapter.id}_like_button"}
                        current_user_id={@current_user_id}
                        chapter={chapter} />
          </div>

          <RecommendForm id={"recommend-form-#{chapter.id}"}
                         current_user_id={@current_user_id}
                         changeset={@changeset}
                         chapter={chapter} />

          <RecommendationList current_user_id={@current_user_id}
                              chapter={chapter}
                              episode={@episode} />
        {/for}
      </div>
    </div>
    """
  end
end
