defmodule PanWeb.Live.Episode.ChapterList do
  use Surface.Component
  alias PanWeb.Live.Chapter.{LikeButton, RecommendForm, RecommendationList}
  alias PanWeb.Endpoint
  import PanWeb.Router.Helpers

  prop(current_user_id, :integer, required: true)
  prop(changeset, :map, required: true)
  prop(episode, :map, required: true)

  def render(assigns) do
    ~F"""
    {#if @episode.chapters != []}
      <h3 id="chapters">Deeplinks to Chapters</h3>

      {#if @current_user_id}
        <div class="row">
          <div class="col-md-8 col-md-offset-4">
            <b>Your recommendation:</b>
          </div>
        </div>
      {/if}

      {#if @current_user_id}
        {#for chapter <- @episode.chapters}
          <div class="row">
            <div class="col-md-4">
              <a href={episode_frontend_path(Endpoint, :player, @episode, t: chapter.start)}
                 rel="http://podlove.org/deep-link">{chapter.start}</a>
              <br/>
              <LikeButton id={"chapter_#{chapter.id}_like_button"}
                          current_user_id={@current_user_id}
                          chapter={chapter} />
              {chapter.title}
            </div>


            <div class="col-md-8">
              <RecommendForm current_user_id={@current_user_id}
                             changeset={@changeset}
                             chapter={chapter} />
            </div>
          </div>
          <RecommendationList current_user_id={@current_user_id}
                              chapter={chapter}
                              episode={@episode} />
        {/for}
      {#else}
        {#for group <- Enum.chunk_every(@episode.chapters, 4, 4, [])}
          <div class="row">
            {#for chapter <- group}
              <div class="col-md-3">
                <a href={episode_frontend_path(Endpoint, :player, @episode, t: chapter.start)}
                   rel="http://podlove.org/deep-link">{chapter.start}</a>
                {chapter.title}
              </div>
            {/for}
          </div>
        {/for}
      {/if}
    {/if}
    """
  end
end
