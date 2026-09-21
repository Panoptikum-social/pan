defmodule Pan.Parser.FeedParsingTest do
  @moduledoc """
  Characterization tests for the XML → map core (Pan.Parser.Iterator and
  Pan.Parser.Analyzer, driven through Pan.Parser.RssFeed.parse_to_map/2).

  They pin down what the parser produces today, and the feed shapes that
  crashed it in production. No database is involved.
  """
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Pan.Parser.RssFeed

  @feed_url "https://example.com/feed.xml"

  # Raw, unescaped markup inside an element parses into a list of text and
  # nested elements (crashed in scrub/1, commit cf82e1f2; later truncated to
  # the first text node). The tags are dropped and all the text is kept.
  # Quinn trims each text node, so the pieces are joined with a space.
  @mixed ~s(Intro <a href="https://example.com">a link <span>inside</span></a> outro)

  # Runs a document through the same steps as the import: Quinn, then
  # parse_to_map. Episodes, enclosures, categories and languages are keyed by
  # random UUIDs, so those maps are reduced to their values.
  defp parse(channel_xml, opts \\ []) do
    namespaces = Keyword.get(opts, :namespaces, "")

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
         xmlns:atom="http://www.w3.org/2005/Atom"
         xmlns:content="http://purl.org/rss/1.0/modules/content/"
         xmlns:podcast="https://podcastindex.org/namespace/1.0" #{namespaces}>
    <channel>
    #{channel_xml}
    </channel>
    </rss>
    """

    {:ok, quinn_map} = RssFeed.xml_to_map(xml)
    {:ok, map} = RssFeed.parse_to_map(quinn_map, @feed_url)
    map
  end

  defp episodes(map), do: map |> Map.get(:episodes, %{}) |> Map.values()

  describe "channel fields" do
    test "title, website, description, explicit, image, language" do
      map =
        parse("""
        <title>My Show</title>
        <link>https://example.com</link>
        <description>About the show</description>
        <language>de-AT</language>
        <itunes:explicit>no</itunes:explicit>
        <itunes:image href="https://example.com/a.jpg"/>
        """)

      assert map.title == "My Show"
      assert map.website == "https://example.com"
      assert map.description == "About the show"
      assert map.explicit == false
      assert map.image_url == "https://example.com/a.jpg"
      assert Map.values(map.languages) == [%{shortcode: "de-AT"}]
    end

    test "the seed values from the feed url are kept when the feed has no title" do
      map = parse("<link>https://example.com</link>")

      assert map.title == "example.com"
      assert map.feed.self_link_url == @feed_url
    end

    test "an empty title, link and summary are skipped instead of crashing" do
      map =
        parse("""
        <title></title>
        <link></link>
        <itunes:summary></itunes:summary>
        <description>Still here</description>
        """)

      assert map.description == "Still here"
      refute Map.has_key?(map, :website)
      refute Map.has_key?(map, :summary)
    end

    test "mixed content keeps all its text in channel fields" do
      map =
        parse("""
        <description>#{@mixed}</description>
        <itunes:summary>#{@mixed}</itunes:summary>
        """)

      assert map.description == "Intro a link inside outro"
      assert map.summary == "Intro a link inside outro"
    end

    test "owner and author are stored under string keys" do
      # This mixed key shape is one of the phase 1 clean-up items in the
      # backlog; when it is unified, this test is the one to change.
      map =
        parse("""
        <itunes:author>Jane</itunes:author>
        <itunes:owner>
          <itunes:name>Jane</itunes:name>
          <itunes:email>jane@example.com</itunes:email>
        </itunes:owner>
        """)

      assert map["author"] == %{name: "Jane"}
      assert map["owner"] == %{name: "Jane", email: "jane@example.com"}
    end

    test "nested itunes categories keep their parent" do
      map =
        parse("""
        <itunes:category text="Technology">
          <itunes:category text="Podcasting"/>
        </itunes:category>
        """)

      categories = map.categories |> Map.values() |> Enum.sort_by(& &1.title)

      assert categories == [
               %{parent: "Technology", title: "Podcasting"},
               %{parent: nil, title: "Technology"}
             ]
    end

    test "an empty channel-level atom:contributor field is skipped" do
      # crashed with a FunctionClauseError, commit 9508c746
      map =
        parse("""
        <title>Show</title>
        <atom:contributor>
          <atom:name>Jane</atom:name>
          <atom:uri></atom:uri>
        </atom:contributor>
        """)

      assert map.title == "Show"
    end

    test "a managingEditor with obfuscated markup does not crash" do
      # Cloudflare email obfuscation, commit eec307f4
      log =
        capture_log(fn ->
          map =
            parse("""
            <title>Show</title>
            <managingEditor><a class="__cf_email__" data-cfemail="ab">[email protected]</a></managingEditor>
            """)

          assert map.title == "Show"
        end)

      assert is_binary(log)
    end

    test "podcast:person with empty or nested content is skipped" do
      map =
        parse("""
        <title>Show</title>
        <podcast:person role="host" href="https://example.com/jane"></podcast:person>
        <podcast:person role="host"><b>x</b></podcast:person>
        """)

      assert map.title == "Show"
    end
  end

  describe "episodes" do
    @episode """
    <item>
      <title>Episode 1</title>
      <guid isPermaLink="false">abc-1</guid>
      <pubDate>Mon, 02 Jan 2023 10:00:00 +0000</pubDate>
      <itunes:duration>01:02:03</itunes:duration>
      <enclosure url="https://example.com/1.mp3" length="123" type="audio/mpeg"/>
      <description>Hello &lt;b&gt;there&lt;/b&gt;</description>
    </item>
    """

    test "title, guid, date, duration, description and enclosure" do
      [episode] = parse(@episode) |> episodes()

      assert episode.title == "Episode 1"
      assert episode.guid == "abc-1"
      assert episode.publishing_date == ~N[2023-01-02 10:00:00]
      assert episode.duration == "01:02:03"
      assert episode.description == "Hello <b>there</b>"

      assert Map.values(episode.enclosures) == [
               %{
                 url: "https://example.com/1.mp3",
                 length: "123",
                 type: "audio/mpeg",
                 guid: nil
               }
             ]
    end

    test "every item becomes its own episode" do
      map = parse(@episode <> String.replace(@episode, "abc-1", "abc-2"))

      assert map |> episodes() |> Enum.map(& &1.guid) |> Enum.sort() == ["abc-1", "abc-2"]
    end

    test "content:encoded becomes the sanitized shownotes" do
      [episode] =
        parse("""
        <item>
          <title>Ep</title>
          <content:encoded><![CDATA[<p>Notes</p><script>alert(1)</script>]]></content:encoded>
        </item>
        """)
        |> episodes()

      assert episode.shownotes =~ "Notes"
      refute episode.shownotes =~ "<script"
    end

    test "mixed content keeps all its text in episode fields" do
      [episode] =
        parse("""
        <item>
          <title>Ep <b>one</b></title>
          <description>#{@mixed}</description>
          <itunes:summary>#{@mixed}</itunes:summary>
          <itunes:subtitle>#{@mixed}</itunes:subtitle>
          <content:encoded>#{@mixed}</content:encoded>
        </item>
        """)
        |> episodes()

      assert episode.title == "Ep one"
      assert episode.description == "Intro a link inside outro"
      assert episode.summary == "Intro a link inside outro"
      assert episode.subtitle == "Intro a link inside outro"
      assert episode.shownotes == "Intro a link inside outro"
    end

    test "an item without any enclosure has no enclosures key" do
      [episode] = parse("<item><title>Text only</title></item>") |> episodes()

      assert episode.title == "Text only"
      refute Map.has_key?(episode, :enclosures)
    end
  end

  describe "unknown tags" do
    test "an unknown channel tag is logged and skipped" do
      log =
        capture_log(fn ->
          map =
            parse("<title>Show</title><totally:unknown>x</totally:unknown>",
              namespaces: ~s(xmlns:totally="urn:x")
            )

          assert map.title == "Show"
        end)

      assert is_binary(log)
    end
  end
end
