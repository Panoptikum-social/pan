defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.{AlternateFeed, Download, Iterator, Persistor}
  require Logger

  # There's no Feed row yet at this point, so unlike the periodic-update path
  # (Pan.Updater.Podcast, via Feed.update_with_redirect_target/2) we can't lean
  # on alternate_feeds history to catch a redirect looping back on itself.
  # Track the URLs seen so far for this import in memory instead, and cap the
  # number of hops we'll chase in case the server keeps sending brand new,
  # never-before-seen URLs.
  @max_redirects 5

  def initial_import(url, feed_id \\ 0, pagecount \\ 1) do
    initial_import(url, feed_id, pagecount, [])
  end

  defp initial_import(url, feed_id, pagecount, visited_urls) do
    case import_to_map(url, feed_id) do
      {:ok, map} ->
        podcast_id = Persistor.initial_import(map, url)
        next_page_url = map[:feed][:next_page_url]
        pagecount = pagecount + 1

        if next_page_url != nil and pagecount < 26 do
          initial_import(next_page_url, feed_id, pagecount, [])
        end

        {:ok, podcast_id}

      {:error, error} ->
        {:error, error}

      {:redirect, redirect_target} ->
        follow_initial_import_redirect(url, feed_id, pagecount, visited_urls, redirect_target)
    end
  end

  defp follow_initial_import_redirect(url, feed_id, pagecount, visited_urls, redirect_target) do
    cond do
      redirect_target in visited_urls ->
        {:error, "loop detected"}

      length(visited_urls) >= @max_redirects ->
        {:error, "too many redirects"}

      true ->
        case initial_import(redirect_target, feed_id, pagecount, [url | visited_urls]) do
          {:ok, podcast_id} ->
            feed = Pan.Repo.get_by(PanWeb.Feed, podcast_id: podcast_id)
            AlternateFeed.get_or_insert(feed.id, %{url: url})
            {:ok, podcast_id}

          {:error, error} ->
            {:error, error}
        end
    end
  end

  def import_to_map(url, logging_id \\ 0) do
    url = String.trim(url)
    Logger.info("#{logging_id} ⬇ #{url}")

    case Download.download(url) do
      {:ok, feed_xml} ->
        feed_xml =
          Pan.Parser.Helpers.remove_comments(feed_xml)
          |> Pan.Parser.Helpers.remove_extra_angle_brackets()
          |> Pan.Parser.Helpers.fix_html_entities()
          |> Pan.Parser.Helpers.fix_character_code_strings()
          |> String.trim()

        case xml_to_map(feed_xml) do
          {:ok, feed_map} -> parse_to_map(feed_map, url)
          {:error, reason} -> {:error, reason}
        end

      {:redirect, redirect_target} ->
        {:redirect, redirect_target}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def xml_to_map(feed_map) do
    try do
      {:ok, Quinn.parse(feed_map)}
    catch
      :exit, error ->
        # xmerl's exit reason is a term (e.g. {:fatal, {:error_scanning_entity_ref,
        # ...}}), not a string — <> on it crashes the crash handler itself.
        {:error, "Quinn error: " <> inspect(error)}
    end
  end

  def parse_to_map(quinn_map, url) do
    map =
      %{
        feed: %{self_link_title: "Feed", self_link_url: url},
        title: Enum.at(String.split(url, "/"), 2)
      }
      |> Iterator.parse(quinn_map)

    {:ok, map}
  end

  # Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc()
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
