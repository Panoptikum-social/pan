defmodule PanWeb.FollowView do
  use PanWeb, :view

  def render("datatable.json", %{follows: follows}) do
    %{follows: Enum.map(follows, &follow_json/1)}
  end

  def follow_json(follow) do
    %{
      id: follow.id,
      follower_id: follow.follower_id,
      follower_name: follow.follower.name,
      podcast_id: follow.podcast_id,
      podcast_title: follow.podcast && follow.podcast.title,
      user_id: follow.user_id,
      user_name: follow.user && follow.user.name,
      category_id: follow.category_id,
      category_title: follow.category && follow.category.title,
      actions: datatable_actions(follow, &follow_path/3)
    }
  end
end
