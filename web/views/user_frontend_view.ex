defmodule Pan.UserFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias Pan.Follow
  alias Pan.Like


  def like_or_unlike(enjoyer_id, user_id) do
    case Repo.get_by(Like, enjoyer_id: enjoyer_id,
                           user_id: user_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "user",
                                    event: "like",
                                    action: "like",
                                    id: user_id] do
          [fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "user",
                                    event: "like",
                                    action: "unlike" ,
                                    id: user_id] do
          [fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("like_button.html", %{current_user_id: current_user_id, user_id: user_id}) do
    like_or_unlike(current_user_id, user_id)
  end


  def follow_or_unfollow(follower_id, user_id) do
    case Repo.get_by(Follow, follower_id: follower_id,
                             user_id: user_id) do
      nil ->
        content_tag :button, class: "btn btn-primary",
                             data: [type: "user",
                                    event: "follow",
                                    action: "follow",
                                    id: user_id] do
          [fa_icon("commenting-o"), " Follow"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "user",
                                    event: "follow",
                                    action: "unfollow" ,
                                    id: user_id] do
          [fa_icon("commenting"), " Unfollow"]
        end
    end
  end


  def render("follow_button.html", %{current_user_id: current_user_id, user_id: user_id}) do
    follow_or_unfollow(current_user_id, user_id)
  end

end
