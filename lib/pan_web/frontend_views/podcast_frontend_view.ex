defmodule PanWeb.PodcastFrontendView do
  use PanWeb, :view
  import Scrivener.HTML
  alias PanWeb.Like
  alias Pan.Repo
  alias PanWeb.Podcast

  def author_button(conn, podcast) do
    persona = Podcast.author(podcast)

    if persona do
      link([fa_icon("user-o"), " ", persona.name],
        to: persona_frontend_path(conn, :show, persona),
        class: "btn btn-xs truncate btn-lavender"
      )
    else
      [fa_icon("user-o"), " Unknown"]
    end
  end

  def render("like_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    podcast = Repo.get!(Podcast, podcast_id)
    like_or_unlike(user_id, podcast)
  end

  def render("follow_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    podcast = Repo.get!(Podcast, podcast_id)
    follow_or_unfollow(user_id, podcast)
  end

  def render("subscribe_button.html", %{user_id: user_id, podcast_id: podcast_id}) do
    podcast = Repo.get!(Podcast, podcast_id)
    subscribe_or_unsubscribe(user_id, podcast)
  end

  def like_or_unlike(user_id, podcast) do
    case Like.find_podcast_like(user_id, podcast.id) do
      nil ->
        content_tag :button,
          class: "btn btn-warning",
          data: [type: "podcast", event: "like", action: "like", id: podcast.id] do
          [Integer.to_string(podcast.likes_count), " ", fa_icon("heart-heroicons-outline-o"), " ", " Like"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "podcast", event: "like", action: "unlike", id: podcast.id] do
          [Integer.to_string(podcast.likes_count), " ", fa_icon("heart-heroicons-outline"), " Unlike"]
        end
    end
  end

  def follow_or_unfollow(user_id, podcast) do
    case Repo.get_by(PanWeb.Follow,
           follower_id: user_id,
           podcast_id: podcast.id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-primary",
          data: [type: "podcast", event: "follow", action: "follow", id: podcast.id] do
          [Integer.to_string(podcast.followers_count), " ", fa_icon("commenting-o"), " Follow"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "podcast", event: "follow", action: "unfollow", id: podcast.id] do
          [Integer.to_string(podcast.followers_count), " ", fa_icon("commenting"), " Unfollow"]
        end
    end
  end

  def subscribe_or_unsubscribe(user_id, podcast) do
    case Repo.get_by(PanWeb.Subscription,
           user_id: user_id,
           podcast_id: podcast.id
         ) do
      nil ->
        content_tag :button,
          class: "btn btn-info",
          data: [type: "podcast", action: "subscribe", event: "subscribe", id: podcast.id] do
          [Integer.to_string(podcast.subscriptions_count), " ", fa_icon("user-o"), " Subscribe"]
        end

      _ ->
        content_tag :button,
          class: "btn btn-success",
          data: [type: "podcast", action: "unsubscribe", event: "subscribe", id: podcast.id] do
          [Integer.to_string(podcast.subscriptions_count), " ", fa_icon("user-heroicons-outline"), " Unsubscribe"]
        end
    end
  end

  def complain_link() do
    PanWeb.EpisodeFrontendView.complain_link()
  end

  def prepare_for_toplist(podcasts) do
    podcasts
    |> Enum.group_by(&select_count/1, &id_title_tuple/1)
    |> Map.to_list()
    # sort by count, descending
    |> Enum.sort_by(fn {count, _} -> count end, &>=/2)
    |> add_rank()
  end

  defp select_count([count, _id, _title]), do: count
  defp id_title_tuple([_count, id, title]), do: {id, title}

  # takes a list of {count, [{id, title}, ...]}
  # and adds a rank, according to the subscribers count
  defp add_rank(counts_and_podcasts) when is_list(counts_and_podcasts) do
    # start loop with an initial rank of 1 and an empty accumulator
    add_rank(counts_and_podcasts, {1, []})
  end

  # recursive loop
  defp add_rank([{count, podcasts} | tail], {rank, acc}) do
    next_rank = rank + length(podcasts)
    next_acc = acc ++ [{rank, count, podcasts}]

    # next round
    add_rank(tail, {next_rank, next_acc})
  end

  # end of list, end loop and return acc
  defp add_rank([], {_rank, acc}), do: acc
end
