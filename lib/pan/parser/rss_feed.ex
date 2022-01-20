defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.{AlternateFeed, Download, Iterator, Persistor}
  require Logger

  def initial_import(url, feed_id \\ 0, pagecount \\ 1) do
    case import_to_map(url, feed_id) do
      {:ok, map} ->
        podcast_id = Persistor.initial_import(map, url)
        next_page_url = map[:feed][:next_page_url]
        pagecount = pagecount + 1

        if next_page_url != nil and pagecount < 26 do
          initial_import(next_page_url, feed_id, pagecount)
        end

        {:ok, podcast_id}

      {:error, error} ->
        {:error, error}

      {:redirect, redirect_target} ->
        case initial_import(redirect_target, feed_id, pagecount) do
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
    Logger.info("=== #{logging_id} ⬇ #{url} ===")

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
        {:error, "Quinn error: " <> error}
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
