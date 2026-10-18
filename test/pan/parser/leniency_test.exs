defmodule Pan.Parser.LeniencyTest do
  use ExUnit.Case, async: true

  alias Pan.Parser.Leniency

  defp feed(channel),
    do:
      ~s(<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>#{channel}</channel></rss>)

  defp labels(xml), do: Enum.map(Leniency.report(xml).xml, & &1.label)

  defp repair(xml, label_part) do
    Enum.find(Leniency.report(xml).xml, &String.contains?(&1.label, label_part))
  end

  test "a standard feed needs no repairs" do
    xml =
      feed("""
      <title>Tom &amp; Jerry &#xC4; &gt;&gt; next</title>
      <!-- a comment with & and < in it -->
      <lastBuildDate>Sat, 01 Apr 2023 19:00:00 GMT</lastBuildDate>
      <item><title>A</title><pubDate>Sat, 1 Apr 2023 19:00:00 +0200</pubDate>
      <dc:date>2023-04-01T19:00:00Z</dc:date></item>
      """)

    assert Leniency.report(xml) == %{xml: [], dates: []}
  end

  test "HTML entities, bare & and < outside CDATA, with examples" do
    xml =
      feed("""
      <title>Tom & Jerry: Gr&uuml;&szlig;e &nbsp; a < b</title>
      <description><![CDATA[Free & easy < here &nbsp;]]></description>
      """)

    assert repair(xml, "HTML entities").count == 3
    assert repair(xml, "bare \"&\"").count == 1
    assert repair(xml, "\"<\" followed by a space").count == 1
    assert hd(repair(xml, "bare \"&\"").examples) =~ "Tom & Jerry"
  end

  test "entities escaped twice" do
    xml = feed("<title>Say &amp;quot;hi&amp;quot;</title>")
    assert repair(xml, "escaped twice").count == 2
  end

  test "a second XML declaration, but not the leading one" do
    xml = feed(~s(<title>A</title><?xml version="1.0"?>))
    assert repair(xml, "second <?xml").count == 1
  end

  test "backspace characters" do
    assert repair(feed("<title>A\bB</title>"), "Backspace").count == 1
  end

  test "Windows-1252 named in the declaration" do
    xml =
      ~s(<?xml version="1.0" encoding="Windows-1252"?><rss version="2.0"><channel><title>A</title></channel></rss>)

    assert repair(xml, "Windows-1252, which").count == 1
  end

  test "invalid UTF-8 counts only when the feed claims UTF-8" do
    latin1 = <<"<title>Gr", 0xFC, "n</title>">>

    assert repair(feed(latin1), "isn't valid UTF-8").count == 1

    declared =
      ~s(<?xml version="1.0" encoding="ISO-8859-1"?><rss version="2.0"><channel>) <>
        latin1 <> "</channel></rss>"

    assert repair(declared, "isn't valid UTF-8") == nil
    refute Enum.any?(labels(declared), &String.contains?(&1, "UTF-8"))
  end

  test "dates in other formats, without a year, and unreadable ones" do
    xml =
      feed("""
      <item><title>A</title><pubDate>2023-04-01</pubDate></item>
      <item><title>B</title><pubDate>2023-04-02</pubDate></item>
      <item><title>C</title><pubDate>Sun Jun 14 16:00:07 GMT</pubDate></item>
      <item><title>D</title><pubDate>sometime</pubDate></item>
      """)

    assert [unreadable, yearless, other] = Leniency.report(xml).dates

    assert %{kind: :unreadable, count: 1, example: "sometime", read_as: "the time of the import"} =
             unreadable

    assert %{kind: :yearless, count: 1} = yearless
    assert yearless.read_as =~ "#{Date.utc_today().year}-06-14"

    assert %{kind: {:format, _}, count: 2, example: "2023-04-01", read_as: "2023-04-01 00:00:00"} =
             other
  end
end
