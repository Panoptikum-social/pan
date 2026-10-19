defmodule Pan.Parser.Feed do
  alias Pan.Repo
  alias Pan.Parser.{AlternateFeed, Download, Helpers}
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
            AlternateFeed.get_or_insert(feed.id, %{
              url: feed_map[:self_link_url],
              title: feed_map[:self_link_url]
            })

            {:ok, feed}
        end
    end
  end

  # The update paths fetch a redirect target in memory and only move the feed
  # there once a feed was actually parsed from it — persisting every hop
  # right away let a temporary redirect to a maintenance page or a homepage
  # (wartung.wdr.de, app.screencast.com, ...) replace a working feed URL for
  # good. visited_urls is the redirect chain of one update, latest first.
  def persist_redirect_target(_id, []), do: {:ok, :no_redirect}

  def persist_redirect_target(id, [redirect_target | _]) do
    update_with_redirect_target(id, Helpers.to_255(redirect_target))
  end

  def update_with_redirect_target(id, redirect_target) do
    {:ok, feed} = get_by_podcast_id(id)

    case redirect_target && Download.check_for_redirect_loop(feed.self_link_url, redirect_target) do
      {:redirect, redirect_target} ->
        AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url, title: feed.self_link_url})

        feed
        |> Feed.changeset(%{self_link_url: redirect_target})
        |> Repo.update(force: true)

      {:error, message} ->
        {:error, message}

      nil ->
        {:error, "empty redirect target"}
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
end
