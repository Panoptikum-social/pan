defmodule Pan.PodcastFrontendView do
  use Pan.Web, :view
  alias Pan.Like
  alias Pan.Repo
  alias Pan.Podcast

  def panel_cycle(counter) do
    Enum.at(["panel-default", "panel-info", "panel-danger",
             "panel-warning", "panel-primary", "panel-success"], rem(counter, 6))
  end


  def like_or_unlike(user_id, podcast_id) do
    case Like.find_podcast_like(user_id, podcast_id) do
      nil ->
        content_tag :button, class: "btn btn-warning",
                             data: [type: "podcast",
                                    event: "like",
                                    action: "like",
                                    id: podcast_id] do
          [Podcast.likes(podcast_id), " ", fa_icon("heart-o"), " ",  " Like"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "podcast",
                                    event: "like",
                                    action: "unlike" ,
                                    id: podcast_id] do
          [Podcast.likes(podcast_id), " ", fa_icon("heart"), " Unlike"]
        end
    end
  end

  def render("like_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    like_or_unlike(user_id, podcast_id)
  end


  def follow_or_unfollow(user_id, podcast_id) do
    case Repo.get_by(Pan.Follow, follower_id: user_id,
                                 podcast_id: podcast_id) do
      nil ->
        content_tag :button, class: "btn btn-primary",
                             data: [type: "podcast",
                                    event: "follow",
                                    action: "follow",
                                    id: podcast_id] do
          [Podcast.follows(podcast_id), " ", fa_icon("commenting-o"), " Follow"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "podcast",
                                    event: "follow",
                                    action: "unfollow" ,
                                    id: podcast_id] do
          [Podcast.follows(podcast_id), " ", fa_icon("commenting"), " Unfollow"]
        end
    end
  end


  def render("follow_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    follow_or_unfollow(user_id, podcast_id)
  end


  def subscribe_or_unsubscribe(user_id, podcast_id) do
    case Repo.get_by(Pan.Subscription, user_id: user_id,
                                       podcast_id: podcast_id) do
      nil ->
        content_tag :button, class: "btn btn-info",
                             data: [type: "podcast",
                                    action: "subscribe",
                                    event: "subscribe",
                                    id: podcast_id] do
          [Podcast.subscriptions(podcast_id), " ", fa_icon("user-o"), " Subscribe"]
        end
      _   ->
        content_tag :button, class: "btn btn-success",
                             data: [type: "podcast",
                                    action: "unsubscribe" ,
                                    event: "subscribe",
                                    id: podcast_id] do
          [Podcast.subscriptions(podcast_id), " ", fa_icon("user"), " Unsubscribe"]
        end
    end
  end


  def render("subscribe_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    subscribe_or_unsubscribe(user_id, podcast_id)
  end
end