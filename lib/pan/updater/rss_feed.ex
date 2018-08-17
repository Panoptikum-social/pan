defmodule Pan.Updater.RssFeed do
  alias Pan.Repo
  alias Pan.Parser.Iterator
  alias Pan.Parser.Helpers, as: H
  alias PanWeb.RssFeed
  require Logger

  def import_to_map(feed_xml, url, podcast_id \\ 0) do
    url = String.trim(url)
    Logger.info("\n\e[96m === #{podcast_id} ⬇ #{url} ===\e[0m")

    with feed_xml <- clean_up_xml(feed_xml),
         {:ok, "go on"} <- check_for_changes(feed_xml, podcast_id),
         {:ok, feed_map} <- xml_to_map(feed_xml) do
      run_the_parser(feed_map, url)
    else
      {:exit, error} -> {:exit, error}
      {:done, "nothing to do"} -> {:done, "nothing to do"}
      {:redirect, redirect_target} -> {:redirect, redirect_target}
      {:error, reason} -> {:error, reason}
    end
  end

  defp clean_up_xml(feed_xml) do
    H.remove_comments(feed_xml)
    |> H.remove_extra_angle_brackets()
    |> H.fix_html_entities()
    |> H.fix_character_code_strings()
    |> String.trim()
    |> H.fix_encoding()
  end

  defp check_for_changes(feed_xml, podcast_id) do
    rss_feed = Repo.get_by(RssFeed, podcast_id: podcast_id)

    if rss_feed do
      if count_changes(rss_feed.content, feed_xml) > 3 do
        RssFeed.changeset(rss_feed, %{content: feed_xml})
        |> Repo.update()

        {:ok, "go on"}
      else
        {:done, "nothing to do"}
      end
    else
      %RssFeed{content: feed_xml, podcast_id: podcast_id}
      |> Repo.insert()

      {:ok, "go on"}
    end
  end

  defp count_changes(nil, _), do: 999

  defp count_changes(old, new) do
    String.splitter(old, "\n")
    |> Enum.zip(String.splitter(new, "\n"))
    |> Enum.count(fn {oldone, newone} -> oldone != newone end)
  end

  defp xml_to_map(feed_map) do
    try do
      {:ok, Quinn.parse(feed_map)}
    catch
      :exit, _ -> {:error, "Quinn parser finds unexpected end"}
    end
  end

  defp run_the_parser(quinn_map, url) do
    map =
      %{
        feed: %{self_link_title: "Feed", self_link_url: url},
        title: Enum.at(String.split(url, "/"), 2)
      }
      |> Iterator.parse(quinn_map)

    {:ok, map}
  end
end
