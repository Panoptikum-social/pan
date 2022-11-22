defmodule Pan.Updater.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Helpers, as: H
  alias Pan.Updater.{Feed, Filter}
  require Logger

  def import_to_map(feed_xml, feed, podcast_id \\ 0, forced \\ false) do
    url = String.trim(feed.self_link_url)

    with feed_xml <- clean_up_xml(feed_xml),
         {:ok, "go on"} <- Feed.hash_changed(feed_xml, feed, forced),
         {:ok, feed_map} <- xml_to_map(feed_xml),
         {:ok, reduced_map} <- Filter.only_new_items_and_new_feed_url(feed_map, podcast_id) do
      try do
        run_the_parser(reduced_map, url)
      rescue
        e ->
          reraise("#{e.message} when importing podcast #{podcast_id}",__STACKTRACE__)
      end
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
