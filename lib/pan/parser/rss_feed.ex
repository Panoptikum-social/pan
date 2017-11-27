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


  def import_to_map(url, logging_id \\ 0, check_changes \\ false) do
    url = String.trim(url)
    Logger.info "\n\e[96m === #{logging_id} ⬇ #{url} ===\e[0m"

    case Download.download(url) do
      {:ok, feed_xml} ->
        feed_xml = Pan.Parser.Helpers.remove_comments(feed_xml)
                   |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                   |> Pan.Parser.Helpers.fix_ampersands()
                   |> Pan.Parser.Helpers.fix_character_code_strings()
                   |> String.trim()

        with  {:ok, "go_on"} <- check_for_changes(feed_xml, logging_id, check_changes),
              {:ok, feed_map} <- xml_to_map(feed_xml) do
          parse_to_map(feed_map, url)
        else
          {:exit, error} ->
            {:exit, error}
          {:done, "nothing to do"} ->
            {:done, "nothing to do"}
        end

      {:redirect, redirect_target} ->
        {:redirect, redirect_target}

      {:error, reason} ->
        {:error, reason}
    end
  end


  def check_for_changes(feed_xml, podcast_id, check_changes) do
    if check_changes or String.valid?(feed_xml) == false do
#       feed_xml =
#         if String.valid?(feed_xml) do
#           feed_xml
#         else
# #          :iconv.convert("ISO-8859-1", "utf-8", feed_xml)
#         end

      case Pan.Repo.get_by(PanWeb.RssFeed, podcast_id: podcast_id) do
        nil ->
          %PanWeb.RssFeed{content: feed_xml, podcast_id: podcast_id}
          |> Repo.insert()
          {:ok, "go_on"}
        rss_feed ->
          if count_changes(rss_feed.content, feed_xml) > 3 do
            rss_feed
            |> PanWeb.RssFeed.changeset(%{content: feed_xml})
            |> Repo.update()

            {:ok, "go_on"}
          else
            {:done, "nothing to do"}
          end
      end
    else
      {:ok, "go_on"}
    end
  end


  def count_changes(old, new) do
    String.splitter(old,"\n")
    |> Enum.zip(String.splitter(new, "\n"))
    |> Enum.count(fn {oldone, newone} -> oldone != newone end)
  end


  def xml_to_map(feed_map) do
    try do
      feed_map = Quinn.parse(feed_map)
      {:ok, feed_map}
    catch
      :exit, _ -> {:error, "Quinn parser finds unexpected end"}
    end
  end


  def parse_to_map(quinn_map, url) do
    map = %{feed: %{self_link_title: "Feed", self_link_url: url},
            title: Enum.at(String.split(url, "/"), 2)}
          |> Iterator.parse(quinn_map)
    {:ok, map}
  end


# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
