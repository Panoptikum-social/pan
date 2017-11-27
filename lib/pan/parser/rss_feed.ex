defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor
  alias Pan.Parser.Download
  alias Pan.Parser.AlternateFeed

  use Pan.Web, :controller
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

      {:error, error} -> {:error, error}

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
    #System.cmd("beep", [])
    url = String.trim(url)
    Logger.info "\n\e[96m === #{logging_id} ⬇ #{url} ===\e[0m"

    case Download.download(url) do
      {:ok, feed_xml} ->
        feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
                   |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                   |> Pan.Parser.Helpers.fix_ampersands()
                   |> Pan.Parser.Helpers.fix_character_code_strings()
                   |> String.trim()
        try do
          feed_map = Quinn.parse(feed_map)
          map = %{feed: %{self_link_title: "Feed", self_link_url: url},
                  title: Enum.at(String.split(url, "/"), 2)}
                |> Iterator.parse(feed_map)
          {:ok, map}
        catch
          :exit, _ -> {:error, "Quinn parser finds unexpected end"}
        end

      {:redirect, redirect_target} ->
        {:redirect, redirect_target}

      {:error, reason} ->
        {:error, reason}
    end
  end


  def parse(feed_map, url) do
    try do
      feed_map = Quinn.parse(feed_map)
      map = %{feed: %{self_link_title: "Feed", self_link_url: url},
              title: Enum.at(String.split(url, "/"), 2)}
            |> Iterator.parse(feed_map)
      {:ok, map}
    catch
      :exit, _ -> {:error, "Quinn parser finds unexpected end"}
    end
  end


# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
