defmodule Pan.Parser.XmlNamesTest do
  use ExUnit.Case, async: true

  alias Pan.Parser.XmlNames

  defp document(body),
    do: ~s(<?xml version="1.0"?><rss version="2.0"><channel>#{body}</channel></rss>)

  test "a feed with the usual names passes" do
    xml =
      document(
        ~s(<title>Show</title><itunes:image href="https://example.com/a.jpg"/><item><title>One</title></item>)
      )

    assert XmlNames.check(xml) == :ok
  end

  test "too many distinct names are refused" do
    xml = document(Enum.map_join(1..300, "", &~s(<t#{&1} a#{&1}="1"/>)))

    assert {:error, message} = XmlNames.check(xml)
    assert message =~ "at most 500"
  end

  test "names starting with non-ASCII letters or a colon, and processing instructions, count" do
    xml = document(Enum.map_join(1..10, "", &~s(<ä#{&1} ö#{&1}="1"/><:c#{&1}/><?pi#{&1} x?>)))

    assert {:error, _} = XmlNames.check(xml, 30)
  end

  test "markup inside CDATA and comments is text to xmerl and doesn't count" do
    html = Enum.map_join(1..300, "", &~s(<span#{&1} class#{&1}="x">))
    xml = document("<description><![CDATA[#{html}]]></description><!-- #{html} -->")

    assert XmlNames.check(xml) == :ok
  end

  test "the feed parser refuses such a document before Quinn sees it" do
    xml = document(Enum.map_join(1..300, "", &~s(<f#{&1} g#{&1}="1"/>)))

    assert {:error, message} = Pan.Parser.RssFeed.xml_to_map(xml)
    assert message =~ "too many distinct"
  end
end
