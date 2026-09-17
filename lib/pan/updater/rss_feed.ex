defmodule Pan.Updater.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Helpers
  alias Pan.Updater.{Feed, Filter}
  require Logger

  def import_to_map(feed_xml, feed, podcast_id \\ 0, forced \\ false) do
    url = String.trim(feed.self_link_url)

    with feed_xml <- clean_up_xml(feed_xml),
         {:ok, "go on"} <- Feed.hash_changed(feed_xml, feed, forced),
         {:ok, feed_map} <- xml_to_map(feed_xml, podcast_id),
         {:ok, reduced_map} <- Filter.only_new_items_and_new_feed_url(feed_map, podcast_id) do
      try do
        run_the_parser(reduced_map, url)
      rescue
        e ->
          reraise("#{Exception.message(e)} when importing podcast #{podcast_id}", __STACKTRACE__)
      end
    else
      {:done, "nothing to do"} -> {:done, "nothing to do"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp clean_up_xml(feed_xml) do
    # fix_encoding/1 has to run before any step that matches on literal
    # multi-byte UTF-8 characters (normalize_nbsp/1's U+00A0 search,
    # fix_html_entities/1's umlaut replacements, ...) — a feed that isn't
    # valid UTF-8 still has those characters as raw single legacy-encoding
    # bytes at this point, so those later steps would find nothing to fix
    # and the raw byte would survive all the way to xmerl uncaught (seen
    # live: a raw 0xA0 nbsp byte from a non-UTF-8 feed sailed past
    # normalize_nbsp/1 when fix_encoding ran last, then fataled in xmerl
    # with :bad_character instead of being normalized to a plain space).
    Helpers.remove_comments(feed_xml)
    |> Helpers.fix_encoding()
    |> Helpers.normalize_nbsp()
    |> Helpers.remove_doctype()
    |> Helpers.remove_duplicate_xml_declarations()
    |> Helpers.remove_extra_angle_brackets()
    |> Helpers.fix_html_entities()
    |> Helpers.fix_character_code_strings()
    |> String.trim()
  end

  defp xml_to_map(feed_xml, podcast_id) do
    try do
      {:ok, Quinn.parse(feed_xml)}
    catch
      :exit, {:fatal, error} ->
        {:error,
         "Podcast: #{podcast_id} Quinn parsing failed with error #{Kernel.inspect(error)}"}
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
