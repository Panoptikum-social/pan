defmodule Pan.Parser.FeedXml do
  @moduledoc """
  The pure core of feed parsing: XML text in, the parser's map out, without
  downloading or storing anything. Shared by the import (Pan.Parser.RssFeed),
  the updater (Pan.Updater.RssFeed), check-feed and Pan.Parser.Leniency.
  """

  alias Pan.Parser.{Helpers, Iterator, XmlNames}

  @doc """
  The parser's map of a feed's XML, with all its episodes.
  """
  def parse_xml(feed_xml, url) do
    with {:ok, quinn_map} <- feed_xml |> clean_xml() |> xml_to_map(),
         do: parse_to_map(quinn_map, url)
  end

  @doc "The fix-ups Panoptikum applies to a feed's XML before parsing it."
  def clean_xml(feed_xml) do
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
    |> String.trim()
  end

  @doc """
  Quinn's node tree of cleaned XML, or `{:error, message}` for XML xmerl
  can't read or with too many distinct names (Pan.Parser.XmlNames).
  """
  def xml_to_map(feed_xml) do
    with :ok <- XmlNames.check(feed_xml), do: {:ok, Quinn.parse(feed_xml)}
  catch
    :exit, error ->
      # xmerl's exit reason is a term (e.g. {:fatal, {:error_scanning_entity_ref,
      # ...}}), not a string — <> on it crashes the crash handler itself.
      {:error, "Quinn error: " <> inspect(error)}
  end

  @doc "The parser's map of Quinn's node tree; `url` is the feed's URL."
  def parse_to_map(quinn_map, url) do
    map =
      %{
        feed: %{self_link_title: "Feed", self_link_url: url},
        title: Enum.at(String.split(url, "/"), 2)
      }
      |> Iterator.parse(quinn_map)

    {:ok, map}
  end
end
