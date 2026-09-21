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
         xmlns:podcast="https://podcastindex.org/namespace/1.0"
         xmlns:psc="http://podlove.org/simple-chapters"
         xmlns:rawvoice="http://www.rawvoice.com/rawvoiceRssModule/"
         xmlns:dc="http://purl.org/dc/elements/1.1/"
         xmlns:bitlove="http://bitlove.org" #{namespaces}>
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

  describe "channel feed data" do
    test "new feed url, last build date and generator" do
      map =
        parse("""
        <itunes:new-feed-url>https://new.example.com/feed</itunes:new-feed-url>
        <lastBuildDate>Tue, 03 Jan 2023 11:00:00 GMT</lastBuildDate>
        <generator>Gen 1.0</generator>
        """)

      assert map.new_feed_url == "https://new.example.com/feed"
      assert map.last_build_date == ~N[2023-01-03 11:00:00]
      assert map.feed.feed_generator == "Gen 1.0"
    end

    test "atom:link rels are sorted into their feed fields" do
      map =
        parse("""
        <atom:link rel="self" title="Mine" href="https://example.com/self"/>
        <atom:link rel="next" href="https://example.com/p2"/>
        <atom:link rel="previous" href="https://example.com/p0"/>
        <atom:link rel="first" href="https://example.com/p1"/>
        <atom:link rel="last" href="https://example.com/p9"/>
        <atom:link rel="hub" href="https://hub.example.com"/>
        <atom:link rel="alternate" title="Alt" href="https://example.com/alt"/>
        <atom:link rel="payment" title="Pay" href="https://pay.example.com"/>
        <atom:link rel="something-else" href="https://example.com/x"/>
        """)

      assert %{
               self_link_title: "Mine",
               self_link_url: "https://example.com/self",
               next_page_url: "https://example.com/p2",
               prev_page_url: "https://example.com/p0",
               first_page_url: "https://example.com/p1",
               last_page_url: "https://example.com/p9",
               hub_link_url: "https://hub.example.com"
             } = map.feed

      assert Map.values(map.feed.alternate_feeds) == [
               %{title: "Alt", url: "https://example.com/alt"}
             ]

      assert map.payment_link_title == "Pay"
      assert map.payment_link_url == "https://pay.example.com"
    end

    test "rawvoice:donate with and without a title" do
      with_title =
        parse(~s(<rawvoice:donate href="https://d.example.com">Donate</rawvoice:donate>))

      without_title = parse(~s(<rawvoice:donate href="https://d.example.com"/>))

      assert with_title.payment_link_title == "Donate"
      assert with_title.payment_link_url == "https://d.example.com"
      assert without_title.payment_link_title == "https://d.example.com"
    end

    test "itunes:subtitle is the description only when there is no description" do
      assert parse("<itunes:subtitle>Sub</itunes:subtitle>").description == "Sub"

      map =
        parse("""
        <description>Real</description>
        <itunes:subtitle>Sub</itunes:subtitle>
        """)

      assert map.description == "Real"
    end

    test "several language tags all end up in the languages" do
      map = parse("<language>en</language><dc:language>de</dc:language>")

      assert map.languages |> Map.values() |> Enum.map(& &1.shortcode) |> Enum.sort() ==
               ["de", "en"]
    end

    test "categories nest to any depth" do
      map =
        parse("""
        <itunes:category text="A">
          <itunes:category text="B"><itunes:category text="C"/></itunes:category>
        </itunes:category>
        """)

      assert map.categories |> Map.values() |> Enum.sort_by(& &1.title) == [
               %{title: "A", parent: nil},
               %{title: "B", parent: "A"},
               %{title: "C", parent: "B"}
             ]
    end

    test "the channel itunes:image wins over the RSS image element" do
      map =
        parse("""
        <image><url>https://example.com/i.png</url><width>1</width></image>
        <itunes:image href="https://example.com/other.png"/>
        """)

      assert map.image_url == "https://example.com/other.png"
      assert map.image == %{image_url: "https://example.com/i.png"}
    end

    test "the title inside an RSS image element is kept" do
      map = parse("<image><url>https://example.com/i.png</url><title>Logo</title></image>")

      assert map.image == %{image_url: "https://example.com/i.png", image_title: "Logo"}
    end

    test "an empty or nested title inside an RSS image element is skipped" do
      empty = parse("<image><url>https://example.com/i.png</url><title></title></image>")
      nested = parse("<image><url>https://example.com/i.png</url><title><b>x</b></title></image>")

      assert empty.image == %{image_url: "https://example.com/i.png"}
      assert nested.image == %{image_url: "https://example.com/i.png"}
    end

    test "tags on the ignore list leave no trace" do
      map = parse("<title>Show</title><itunes:block>yes</itunes:block>")

      refute Map.has_key?(map, :block)
      assert map.title == "Show"
    end
  end

  describe "channel people" do
    test "later author tags merge over earlier ones" do
      map =
        parse("""
        <itunes:author>Jane</itunes:author>
        <atom:author><atom:name>Ann</atom:name><atom:email>ann@example.com</atom:email></atom:author>
        """)

      assert map["author"] == %{name: "Ann", email: "ann@example.com"}
    end

    test "a plain managingEditor is stored as managing_editor" do
      map = parse("<managingEditor>ed@example.com (Ed)</managingEditor>")

      assert map["managing_editor"] == %{name: "ed@example.com (Ed)"}
    end

    test "atom:contributor collects name, uri and pid" do
      map =
        parse("""
        <atom:contributor>
          <atom:name>Con</atom:name>
          <atom:uri>https://con.example.com</atom:uri>
          <panoptikum:pid>pid1</panoptikum:pid>
        </atom:contributor>
        """)

      assert Map.values(map.contributors) == [
               %{name: "Con", uri: "https://con.example.com", pid: "pid1"}
             ]
    end

    test "podcast:person defaults the role to host and normalizes it" do
      map =
        parse("""
        <podcast:person role=" Guest " href="https://p.example.com" img="https://p.example.com/i.jpg">Pat</podcast:person>
        <podcast:person>Default</podcast:person>
        """)

      people = map.contributors |> Map.values() |> Enum.sort_by(& &1.name)

      assert people == [
               %{name: "Default", role: "host"},
               %{
                 name: "Pat",
                 role: "guest",
                 uri: "https://p.example.com",
                 image_url: "https://p.example.com/i.jpg"
               }
             ]
    end
  end

  describe "episode details" do
    defp episode(item_xml), do: parse("<item>#{item_xml}</item>") |> episodes() |> hd()

    test "guid variants and link" do
      assert episode("<itunes:guid>g1</itunes:guid>").guid == "g1"
      assert episode("<id>g2</id>").guid == "g2"
      assert episode("<link>https://example.com/1</link>").link == "https://example.com/1"
    end

    test "an empty title becomes \"No title\"" do
      assert episode("<title></title>").title == "No title"
      assert episode("<itunes:title></itunes:title>").title == "No title"
    end

    test "an empty pubDate falls back to the current time" do
      date = episode("<pubDate></pubDate>").publishing_date

      assert NaiveDateTime.diff(NaiveDateTime.utc_now(), date) in -5..5
    end

    test "duration variants" do
      assert episode("<itunes:duration>12:00</itunes:duration>").duration == "12:00"
      assert episode("<duration>3600</duration>").duration == "3600"
    end

    test "episode atom:link rels" do
      episode =
        episode("""
        <atom:link rel="http://podlove.org/deep-link" href="https://deep.example.com"/>
        <atom:link rel="payment" title="P" href="https://pay.example.com"/>
        <atom:link rel="alternate" href="https://example.com/alt"/>
        <atom:link rel="replies" href="https://example.com/replies"/>
        <atom:link href="https://example.com/plain"/>
        """)

      assert episode.deep_link == "https://deep.example.com"
      assert episode.payment_link_title == "P"
      assert episode.payment_link_url == "https://pay.example.com"
      assert episode.link == "https://example.com/plain"
    end

    test "an episode atom:link with an unlisted rel is skipped" do
      # used to raise a CaseClauseError; the channel-level links already skipped them
      episode =
        episode("""
        <title>Ep</title>
        <atom:link rel="enclosure" href="https://example.com/x"/>
        """)

      assert episode.title == "Ep"
      refute Map.has_key?(episode, :link)
    end

    test "several enclosures, with the bitlove guid" do
      episode =
        episode("""
        <enclosure url="https://example.com/a.mp3" length="1" type="audio/mpeg" bitlove:guid="bl"/>
        <enclosure url="https://example.com/a.ogg" length="2" type="audio/ogg"/>
        """)

      assert episode.enclosures |> Map.values() |> Enum.sort_by(& &1.length) == [
               %{url: "https://example.com/a.mp3", length: "1", type: "audio/mpeg", guid: "bl"},
               %{url: "https://example.com/a.ogg", length: "2", type: "audio/ogg", guid: nil}
             ]
    end

    test "an overlong enclosure url is cut to 255 bytes" do
      url = "https://example.com/" <> String.duplicate("a", 300)
      episode = episode(~s(<enclosure url="#{url}" length="1" type="audio/mpeg"/>))

      [enclosure] = Map.values(episode.enclosures)
      assert byte_size(enclosure.url) == 255
    end

    test "podlove simple chapters" do
      episode =
        episode("""
        <psc:chapters>
          <psc:chapter start="00:00:00" title="Intro"/>
          <psc:chapter start="00:05:00" title="Main"/>
        </psc:chapters>
        """)

      assert episode.chapters |> Map.values() |> Enum.sort_by(& &1.start) == [
               %{start: "00:00:00", title: "Intro"},
               %{start: "00:05:00", title: "Main"}
             ]
    end

    test "episode author, image and subtitle" do
      episode =
        episode("""
        <itunes:author>Jane</itunes:author>
        <itunes:image href="https://example.com/ep.png"/>
        <itunes:subtitle>Sub</itunes:subtitle>
        """)

      assert episode.author == %{name: "Jane"}
      assert episode.image_url == "https://example.com/ep.png"
      assert episode.subtitle == "Sub"
    end

    test "episode contributors from atom, dc and podcast:person" do
      episode =
        episode("""
        <atom:contributor><atom:name>Con</atom:name><atom:email>c@example.com</atom:email></atom:contributor>
        <dc:contributor>Dee</dc:contributor>
        <podcast:person role="guest">Gus</podcast:person>
        """)

      assert episode.contributors |> Map.values() |> Enum.sort_by(& &1.name) == [
               %{name: "Con", email: "c@example.com"},
               %{name: "Dee", uri: "Dee"},
               %{name: "Gus", role: "guest"}
             ]
    end

    test "an unknown episode tag is skipped" do
      capture_log(fn ->
        assert episode("<title>Ep</title><weird>zz</weird>").title == "Ep"
      end)
    end
  end

  describe "container tags with unexpected content" do
    # Found by feeding every known tag as plain text, mixed content and empty
    # element; each of these raised a FunctionClauseError.
    test "plain text inside a channel atom:contributor is skipped" do
      map =
        parse("""
        <title>Show</title>
        <atom:contributor>Jane</atom:contributor>
        <atom:contributor>Text <atom:name>Con</atom:name> more text</atom:contributor>
        """)

      assert map.title == "Show"
      assert Map.values(map.contributors) == [%{name: "Con"}]
    end

    test "plain text inside an episode atom:contributor is skipped" do
      episode =
        episode("""
        <title>Ep</title>
        <atom:contributor>Jane</atom:contributor>
        <atom:contributor>Text <atom:name>Con</atom:name></atom:contributor>
        """)

      assert episode.title == "Ep"
      assert Map.values(episode.contributors) == [%{name: "Con"}]
    end

    test "plain text inside psc:chapters is skipped" do
      episode =
        episode("""
        <title>Ep</title>
        <psc:chapters>Some text <psc:chapter start="00:00:00" title="Intro"/></psc:chapters>
        """)

      assert Map.values(episode.chapters) == [%{start: "00:00:00", title: "Intro"}]
    end

    test "an itunes:category with an unknown child keeps the category" do
      map =
        parse("""
        <itunes:category text="Technology">
          <itunes:name>x</itunes:name>
          <itunes:category text="Podcasting"/>
        </itunes:category>
        """)

      assert map.categories |> Map.values() |> Enum.sort_by(& &1.title) == [
               %{title: "Podcasting", parent: "Technology"},
               %{title: "Technology", parent: nil}
             ]
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
