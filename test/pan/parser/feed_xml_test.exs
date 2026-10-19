defmodule Pan.Parser.FeedXmlTest do
  use ExUnit.Case, async: true

  alias Pan.Parser.FeedXml

  @url "https://example.com/feed.xml"

  defp feed(channel),
    do: ~s(<?xml version="1.0"?><rss version="2.0"><channel>#{channel}</channel></rss>)

  test "parse_xml turns a feed into the parser's map, episodes included" do
    xml = feed("<title>Show</title><item><title>One</title><guid>1</guid></item>")

    assert {:ok, map} = FeedXml.parse_xml(xml, @url)
    assert map[:title] == "Show"
    assert [%{title: "One"}] = Map.values(map[:episodes])
    assert map[:feed][:self_link_url] == @url
  end

  test "malformed XML is an error, not a crash" do
    assert {:error, "Quinn error: " <> _} = FeedXml.parse_xml(feed("<title>Show</titel>"), @url)
  end

  test "a Latin-1 feed with a raw non-breaking space byte still parses" do
    # fix_encoding has to run before normalize_nbsp, see clean_xml/1
    xml =
      ~s(<?xml version="1.0" encoding="ISO-8859-1"?><rss version="2.0"><channel><title>Caf\xE9\xA0Show</title></channel></rss>)

    assert {:ok, map} = FeedXml.parse_xml(xml, @url)
    assert map[:title] == "Café Show"
  end

  test "comments are removed before parsing" do
    xml = feed("<!-- <title>Wrong</title> --><title>Right</title>")

    assert {:ok, %{title: "Right"}} = FeedXml.parse_xml(xml, @url)
  end
end
