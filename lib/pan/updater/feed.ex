defmodule Pan.Updater.Feed do
  alias Pan.Repo
  alias PanWeb.Feed
  require Logger

  def needs_update(feed, podcast) do
    if feed.no_headers_available do
      {:ok, "go on"}
    else
      headers = [
        "User-Agent":
          "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.io/)"
      ]

      options = [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]

      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} =
        HTTPoison.head(feed.self_link_url, headers, options)

      headermap = Enum.into(headers, %{})
      check_headers(podcast, feed, headermap["ETag"], headermap["Last-Modified"])
    end
  end

  def check_headers(_, feed, nil, nil) do
    Feed.changeset(feed, %{no_headers_avaiable: true})
    |> Repo.update()
    {:ok, "go on"}
  end

  def check_headers(podcast, feed, nil, last_modified_header) do
    {:ok, last_modified} =
      last_modified_header
      |> Timex.parse("{WDshort}, {D} {Mshort} {YYYY} {ISOtime} {Zname}")

    if feed.trust_last_modified and last_modified == feed.last_modified do
      # last_modified unchanged and trustworthy
      {:done, "nothing to do"}
    else
      check_trustwortyness(feed, podcast, last_modified)
    end
  end

  def check_headers(_, feed, etag, _) do
    if etag == feed.etag do
      # etag unchanged
      {:done, "nothing to do"}
    else
      Feed.changeset(feed, %{etag: etag})
      |> Repo.update()

      {:ok, "go on"}
    end
  end

  def check_trustwortyness(feed, podcast, last_modified) do
    # We allow for a difference of (rather arbitrary) 100 seconds between last_modified header
    # and the last build date of the podcast or the publishing date of latest episode:
    if abs(Timex.diff(podcast.last_build_date, last_modified, :seconds)) < 100 or
         abs(Timex.diff(podcast.latest_episode_publishing_date, last_modified, :seconds)) < 100 do
      Feed.changeset(feed, %{last_modified: last_modified, trust_last_modified: true})
      |> Repo.update()

      {:done, "nothing to do"}
    else
      Feed.changeset(feed, %{last_modified: last_modified, trust_last_modified: false})
      |> Repo.update()

      {:ok, "go on"}
    end
  end
end
