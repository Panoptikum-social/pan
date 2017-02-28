defmodule Pan.UserFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias Pan.Follow
  alias Pan.Like
  alias Pan.User


  def pro(user) do
    user.pro_until != nil && Ecto.DateTime.compare(user.pro_until, now()) == :gt
  end


  def disabled(user) do
    if user.pro_until == nil || Ecto.DateTime.compare(user.pro_until, now()) == :lt do
      "disabled"
    else
      ""
    end
  end


  def now() do
    Timex.now()
    |> Timex.to_erl()
    |> Ecto.DateTime.from_erl()
  end


  def like_or_unlike(enjoyer_id, user_id) do
    case Repo.get_by(Like, enjoyer_id: enjoyer_id,
                           user_id: user_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "user",
                                    event: "like",
                                    action: "like",
                                    id: user_id] do
          [User.likes(user_id), " ", fa_icon("heart-o"), " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "user",
                                    event: "like",
                                    action: "unlike" ,
                                    id: user_id] do
          [User.likes(user_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
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
          [User.follows(user_id), " ", fa_icon("commenting-o"), " Follow"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "user",
                                    event: "follow",
                                    action: "unfollow" ,
                                    id: user_id] do
          [User.follows(user_id), " ", fa_icon("commenting"), " Unfollow"]
        end
    end
  end


  def render("like_button.html", %{current_user_id: current_user_id, user_id: user_id}) do
    like_or_unlike(current_user_id, user_id)
  end

  def render("follow_button.html", %{current_user_id: current_user_id, user_id: user_id}) do
    follow_or_unfollow(current_user_id, user_id)
  end


  def podcast_button(conn, podcast) do
    link [fa_icon("podcast"), " ", podcast.title],
         to: podcast_frontend_path(conn, :show, podcast),
         class: "btn btn-default btn-xs",
         style: "color: #000"
  end


  def episode_button(conn, episode) do
    link [fa_icon("headphones"), " ", truncate(episode.title, 40)],
         to: episode_frontend_path(conn, :show, episode),
         class: "btn btn-primary btn-xs",
         style: "color: #fff"
  end


  def chapter_label(chapter) do
    [fa_icon("indent"), " ", chapter.title]
  end


  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end
