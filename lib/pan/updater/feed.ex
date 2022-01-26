defmodule Pan.Updater.Feed do
  alias Pan.Repo
  alias PanWeb.Feed
  import Pan.Parser.Helpers, only: [md5hash: 1, to_naive_datetime: 1]
  require Logger

  def needs_update(feed, podcast, forced \\ false) do
    if forced != false || feed.no_headers_available do
      {:ok, "go on"}
    else
      headers = [
        "User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.io/)"
      ]

      options = [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]

      case HTTPoison.head(feed.self_link_url, headers, options) do
        {:ok, %HTTPoison.Response{headers: headers}} ->
          headermap = Enum.into(headers, %{})
          check_headers(podcast, feed, headermap["ETag"], headermap["Last-Modified"])

        {:error, _error} ->
          {:ok, "go on"}
      end
    end
  end

  defp check_headers(_, feed, nil, nil) do
    Feed.changeset(feed, %{no_headers_available: true})
    |> Repo.update()

    {:ok, "go on"}
  end

  defp check_headers(podcast, feed, nil, last_modified_header) do
    if last_modified_header != "" do
      last_modified = to_naive_datetime(last_modified_header)

      if feed.trust_last_modified and last_modified == feed.last_modified do
        # last_modified unchanged and trustworthy
        {:done, "nothing to do"}
      else
        check_trustwortyness(feed, podcast, last_modified)
      end
    else
      {:ok, "go on"}
    end
  end

  defp check_headers(_, feed, etag, _) do
    if etag == feed.etag do
      # etag unchanged
      {:done, "nothing to do"}
    else
      Feed.changeset(feed, %{etag: etag})
      |> Repo.update()

      {:ok, "go on"}
    end
  end

  defp check_trustwortyness(feed, podcast, last_modified) do
    # We allow for a difference of (rather arbitrary) 100 seconds between last_modified header
    # and the last build date of the podcast or the publishing date of latest episode:
    if (podcast.last_build_date &&
          abs(NaiveDateTime.diff(podcast.last_build_date, last_modified)) < 100) ||
         abs(NaiveDateTime.diff(podcast.latest_episode_publishing_date, last_modified)) < 100 do
      Feed.changeset(feed, %{last_modified: last_modified, trust_last_modified: true})
      |> Repo.update()

      {:done, "nothing to do"}
    else
      Feed.changeset(feed, %{last_modified: last_modified, trust_last_modified: false})
      |> Repo.update()

      {:ok, "go on"}
    end
  end

  def hash_changed(feed_xml, feed, forced) do
    case forced == false && feed.hash do
      false ->
        {:ok, "go on"}

      nil ->
        update_hash_and_go_on(feed, feed_xml)

      feed_hash ->
        if feed_hash == md5hash(feed_xml) do
          {:done, "nothing to do"}
        else
          update_hash_and_go_on(feed, feed_xml)
        end
    end
  end

  defp update_hash_and_go_on(feed, feed_xml) do
    Feed.changeset(feed, %{hash: md5hash(feed_xml)})
    |> Repo.update()

    {:ok, "go on"}
  end
end
