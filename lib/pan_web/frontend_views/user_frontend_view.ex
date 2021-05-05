defmodule PanWeb.UserFrontendView do
  use PanWeb, :view
  import Scrivener.HTML
  alias Pan.Repo
  alias PanWeb.Follow
  alias PanWeb.Like
  alias PanWeb.User
  import NaiveDateTime

  def pro(user) do
    user.pro_until != nil && compare(user.pro_until, utc_now()) == :gt
  end

  def pro_days_left(user) do
    Timex.diff(user.pro_until, Timex.now(), :days)
  end

  def alert_class(user) do
    cond do
      pro_days_left(user) > 30 -> "alert-success"
      pro_days_left(user) > 7 -> "alert-warning"
      pro_days_left(user) < 7 -> "alert-danger"
    end
  end

  def disabled(user) do
    if user.pro_until == nil || compare(user.pro_until, utc_now()) == :lt do
      "disabled"
    else
      ""
    end
  end

  def like_or_unlike(enjoyer_id, user_id) do
    case Repo.get_by(Like,
           enjoyer_id: enjoyer_id,
           user_id: user_id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-warning",
          data: [type: "user", event: "like", action: "like", id: user_id] do
          [User.likes(user_id), " ", icon("heart-heroicons-outline"), " Like"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "user", event: "like", action: "unlike", id: user_id] do
          [User.likes(user_id), " ", icon("heart-heroicons-outline"), " Unlike"]
        end
    end
  end

  def follow_or_unfollow(follower_id, user_id) do
    case Repo.get_by(Follow,
           follower_id: follower_id,
           user_id: user_id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-primary",
          data: [type: "user", event: "follow", action: "follow", id: user_id] do
          [User.follows(user_id), " ", icon("annotation-heroicons-outline"), " Follow"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "user", event: "follow", action: "unfollow", id: user_id] do
          [User.follows(user_id), " ", icon("commenting"), " Unfollow"]
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
    link([icon("podcast"), " ", podcast.title],
      to: podcast_frontend_path(conn, :show, podcast),
      class: "btn btn-default btn-xs",
      style: "color: #000"
    )
  end

  def episode_button(conn, episode) do
    link([icon("headphones-lineawesome-solid"), " ", truncate_string(episode.title, 40)],
      to: episode_frontend_path(conn, :show, episode),
      class: "btn btn-primary btn-xs",
      style: "color: #fff"
    )
  end

  def chapter_label(chapter) do
    [icon("indent"), " ", chapter.title]
  end

  def format_date(date) do
    Timex.to_date(date)
    |> Timex.format!("%e.%m.%Y", :strftime)
  end
end
