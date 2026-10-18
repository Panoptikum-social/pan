defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.{AlternateFeed, Download, Iterator, Persistor}
  require Logger

  # Like the update paths (Pan.Updater.Podcast, Pan.Parser.Podcast), track the
  # URLs seen so far for this import to catch a redirect looping back on
  # itself, and cap the number of hops we'll chase in case the server keeps
  # sending brand new, never-before-seen URLs.
  @max_redirects 5

  def initial_import(url, feed_id \\ 0, pagecount \\ 1) do
    initial_import(url, feed_id, pagecount, [], nil)
  end

  # podcast_id is nil for the first page and the podcast that page created or
  # found for the following pages, see Pan.Parser.Podcast.get_or_insert/3.
  defp initial_import(url, feed_id, pagecount, visited_urls, podcast_id) do
    with {:ok, map} <- import_to_map(url, feed_id),
         {:ok, podcast_id} <- Persistor.initial_import(map, podcast_id, [url | visited_urls]) do
      next_page_url = map[:feed][:next_page_url]
      pagecount = pagecount + 1

      if next_page_url != nil and pagecount < 26 do
        initial_import(next_page_url, feed_id, pagecount, [], podcast_id)
      end

      {:ok, podcast_id}
    else
      {:redirect, redirect_target} ->
        follow_initial_import_redirect(
          url,
          feed_id,
          pagecount,
          visited_urls,
          redirect_target,
          podcast_id
        )

      {:error, error} ->
        {:error, error}
    end
  end

  defp follow_initial_import_redirect(
         url,
         feed_id,
         pagecount,
         visited_urls,
         redirect_target,
         podcast_id
       ) do
    cond do
      redirect_target in visited_urls ->
        {:error, "loop detected"}

      length(visited_urls) >= @max_redirects ->
        {:error, "too many redirects"}

      true ->
        case initial_import(redirect_target, feed_id, pagecount, [url | visited_urls], podcast_id) do
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
        parse_xml(feed_xml, url)

      {:redirect, redirect_target} ->
        {:redirect, redirect_target}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  The parser's map of a feed's XML, with all its episodes, without
  downloading or storing anything.
  """
  def parse_xml(feed_xml, url) do
    with {:ok, feed_map} <- feed_xml |> clean_xml() |> xml_to_map(),
         do: parse_to_map(feed_map, url)
  end

  @doc "The fix-ups Panoptikum applies to a feed's XML before parsing it."
  def clean_xml(feed_xml) do
    Pan.Parser.Helpers.remove_comments(feed_xml)
    |> Pan.Parser.Helpers.fix_encoding()
    |> Pan.Parser.Helpers.normalize_nbsp()
    |> Pan.Parser.Helpers.remove_doctype()
    |> Pan.Parser.Helpers.remove_duplicate_xml_declarations()
    |> Pan.Parser.Helpers.remove_extra_angle_brackets()
    |> Pan.Parser.Helpers.fix_html_entities()
    |> Pan.Parser.Helpers.fix_character_code_strings()
    |> String.trim()
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
