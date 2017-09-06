defmodule PanWeb.LikeView do
  use Pan.Web, :view

  def render("datatable.json", %{likes: likes}) do
    %{likes: Enum.map(likes, &like_json/1)}
  end

  def like_json(like) do
    %{id:             like.id,
      enjoyer_id:     like.enjoyer_id,
      enjoyer_name:   like.enjoyer.name,
      podcast_id:     like.podcast_id,
      podcast_title:  like.podcast && like.podcast.title,
      episode_id:     like.episode_id,
      episode_title:  like.episode && like.episode.title,
      chapter_id:     like.chapter_id,
      chapter_title:  like.chapter && like.chapter.title,
      user_id:        like.user_id,
      user_name:      like.user && like.user.name,
      category_id:    like.category_id,
      category_title: like.category && like.category.title,
      actions:        datatable_actions(like, &like_path/3)}
  end
end
