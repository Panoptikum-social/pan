defmodule Pan.Parser.Feed do
  use Pan.Web, :controller
  alias Pan.Parser.AlternateFeed
  alias PanWeb.{Feed, Podcast}
  alias Pan.Repo

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

    if redirect_target && String.starts_with?(redirect_target, "http") do
      AlternateFeed.get_or_insert(feed.id, %{url: feed.self_link_url,
                                             title: feed.self_link_url})
      feed
      |> Feed.changeset(%{self_link_url: redirect_target})
      |> Repo.update([force: true])
    end
  end


  def get_by_podcast_id(id) do
    case Repo.get_by(Feed, podcast_id: id) do
      nil ->
        {:error, :not_found}
      feed ->
        {:ok, feed}
    end
  end


  def needs_update(podcast_id) do
    feed = Repo.get_by(Feed, podcast_id: podcast_id)
    headers = ["User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0"]
    options = [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]
    {:ok, %HTTPoison.Response{status_code: 200,
                              headers: headers}} = HTTPoison.head(feed.self_link_url, headers, options)

    headermap = Enum.into(headers, %{})
    check_headers(podcast_id, feed, headermap["ETag"], headermap["Last-Modified"])
  end


  def check_headers(_, _, nil, nil), do: {:ok, "go_on"}
  def check_headers(podcast_id, feed, nil, last_modified_header) do
    last_modified = last_modified_header
                    |> Timex.parse("{WDshort}, {D} {Mshort} {YYYY} {ISOtime} {Zname}")
    if feed.trust_last_modified and last_modified == feed.last_modified do
      {:done, "nothing to do"} # last_modified unchanged and trustworthy
    else
      check_trustwortyness(feed, podcast_id, last_modified)
    end
  end
  def check_headers(_, feed, etag, _) do
    if etag == feed.etag do
      {:done, "nothing to do"} # etag unchanged
    else
      Feed.changeset(feed, %{etag: etag})
      |> Repo.update()
      {:ok, "go_on"}
    end
  end


  def check_trustwortyness(feed, podcast_id, last_modified) do
    podcast = Repo.get(Podcast, podcast_id)

    # We allow for a difference of (rather arbitrary) 100 seconds between last_modified header
    # and the last build date of the podcast or the publishing date of latest episode:
    if abs(Timex.diff(podcast.last_build_date,                last_modified, :seconds) < 100) or
       abs(Timex.diff(podcast.latest_episode_publishing_date, last_modified, :seconds) < 100) do
      Feed.changeset(feed, %{last_modified: last_modified,
                             trust_last_modified: true})
      |> Repo.update()
      {:done, "nothing to do"}
    else
      Feed.changeset(feed, %{last_modified: last_modified,
                             trust_last_modified: false})
      |> Repo.update()
      {:ok, "go_on"}
    end
  end
end