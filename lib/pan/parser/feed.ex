defmodule Pan.Parser.Feed do
  import Ecto.Query
  alias Pan.Repo
  alias Pan.Parser.AlternateFeed
  alias PanWeb.Feed

  def get_or_insert(feed_map, podcast_id) do
    case Repo.get_by(Feed, podcast_id: podcast_id) do
      nil ->
        %Feed{podcast_id: podcast_id}
        |> Map.merge(feed_map)
        |> Repo.insert()
      feed ->
        case feed.self_link_url == feed_map[:self_link_url] do
          true ->
            {:ok, feed}
          false ->
            AlternateFeed.get_or_insert(feed.id, %{url:   feed_map[:self_link_url],
                                                   title: feed_map[:self_link_url]})
            {:ok, feed}
        end
    end
  end


  def update_with_redirect_target(id, redirect_target) do
    {:ok, feed} = get_by_podcast_id(id)

    case redirect_target && check_for_redirect_loop(feed.self_link_url, redirect_target, id) do
      {:redirect, redirect_target} ->
        AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url,
                                               title: feed.self_link_url})
        feed
        |> Feed.changeset(%{self_link_url: redirect_target})
        |> Repo.update([force: true])

      {:error, message} -> {:error, message}
      nil -> {:error, "empty redirect target"}
    end
  end


  def check_for_redirect_loop(url, redirect_target, id) do
    redirect_target =
      case String.starts_with?(redirect_target, "http") do
        true -> redirect_target
        false ->
          domain = String.split(url, "/", parts: 3, trim: true)
                   |> Enum.drop(-1)
                   |> Enum.join("//")
          "#{domain}/#{redirect_target}"
      end

    there_is_a_loop_here = alternate_feed_urls(id)
                           |> Enum.member?(redirect_target)

    cond do
      redirect_target == url ->
        {:error, "redirects to itself"}
      there_is_a_loop_here ->
        {:error, "loop detected"}
      true ->
        {:redirect, redirect_target}
    end
  end


  def get_by_podcast_id(id) do
    case Repo.get_by(Feed, podcast_id: id) do
      nil ->
        {:error, "not found"}
      feed ->
        {:ok, feed}
    end
  end


  def alternate_feed_urls(id) do
    from(a in PanWeb.AlternateFeed, where: a.feed_id == ^id,
                                    select: a.url)
    |> Repo.all()
  end
end