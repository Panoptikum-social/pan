defmodule Pan.PodcastFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML
  alias Pan.Like
  alias Pan.Repo
  alias Pan.Podcast


  def author_button(conn, podcast) do
    persona = Podcast.author(podcast)
    if persona do
      link [fa_icon("user-o"), " ", persona.name],
           to: persona_frontend_path(conn, :show, persona),
           class: "btn btn-xs truncate btn-pink-rose"
    else
      [fa_icon("user-o"), " Unknown"]
    end
  end


  def render("like_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    like_or_unlike(user_id, podcast_id)
  end

  def render("follow_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    follow_or_unfollow(user_id, podcast_id)
  end

  def render("subscribe_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    subscribe_or_unsubscribe(user_id, podcast_id)
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


  def complain_link() do
    Pan.EpisodeFrontendView.complain_link()
  end
end