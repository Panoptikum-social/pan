defmodule Pan.Parser.HelpersTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Pan.Parser.Helpers

  # The order of the cleanup steps every XML entry point runs before Quinn
  # (see Pan.Parser.RssFeed, Pan.Updater.RssFeed, Pan.Parser.Category and
  # Pan.OpmlParser.Opml, which each spell it out on their own).
  defp clean(xml) do
    xml
    |> Helpers.remove_comments()
    |> Helpers.fix_encoding()
    |> Helpers.normalize_nbsp()
    |> Helpers.remove_doctype()
    |> Helpers.remove_duplicate_xml_declarations()
    |> Helpers.remove_extra_angle_brackets()
    |> Helpers.fix_html_entities()
    |> Helpers.fix_character_code_strings()
    |> String.trim()
  end

  # Whether xmerl (through Quinn) can parse the document. xmerl logs every
  # fatal error, which would only be noise here.
  defp parses?(xml) do
    capture_log(fn ->
      send(self(), {:parsed, try_parse(xml)})
    end)

    assert_received {:parsed, result}
    result
  end

  defp try_parse(xml) do
    Quinn.parse(xml)
    true
  catch
    :exit, _reason -> false
  end

  defp feed(inner),
    do: ~s(<?xml version="1.0" encoding="UTF-8"?><rss><channel>#{inner}</channel></rss>)

  # Text of the <title> element inside <rss><channel>, as Quinn returns it.
  defp title(xml) do
    [%{value: [%{value: children}]}] = Quinn.parse(xml)
    %{value: [text]} = Enum.find(children, &(&1.name == :title))
    text
  end

  describe "normalize_nbsp/1" do
    test "a literal U+00A0 between attributes crashed xmerl, a plain space does not" do
      raw = feed(~s(<item><enclosure url="http://x.org/a.mp3" type="audio/mpeg"/></item>))

      refute parses?(raw)
      assert Helpers.normalize_nbsp(raw) |> parses?()
    end

    test "replaces every occurrence with an ASCII space" do
      assert Helpers.normalize_nbsp("a b c") == "a b c"
    end
  end

  describe "escape_stray_ampersands/1" do
    test "escapes ampersands that cannot start a reference" do
      assert Helpers.escape_stray_ampersands("Tom & Jerry") == "Tom &amp; Jerry"
      assert Helpers.escape_stray_ampersands("?a=1&2=x") == "?a=1&amp;2=x"
      assert Helpers.escape_stray_ampersands("trailing &") == "trailing &amp;"
      assert Helpers.escape_stray_ampersands("&(_0x1a2b)") == "&amp;(_0x1a2b)"
    end

    test "leaves anything that looks like a real reference alone" do
      for reference <- ["&amp;", "&nbsp;", "&auml;", "&#160;", "&#xC4;", "&unknown;"] do
        assert Helpers.escape_stray_ampersands(reference) == reference
      end
    end

    test "obfuscated JavaScript in show notes no longer crashes xmerl" do
      raw = feed("<title>x</title><description>if (a &(_0x1a2b) && b) {}</description>")

      refute parses?(raw)
      assert clean(raw) |> parses?()
    end
  end

  describe "fix_html_entities/1" do
    test "decodes HTML named entities that xmerl does not know" do
      raw = feed("<title>Gr&uuml;&szlig;e &ndash; &Auml;rger &hellip; &mdash;</title>")

      refute parses?(raw)

      cleaned = clean(raw)
      assert parses?(cleaned)
      assert title(cleaned) == "Grüße – Ärger … —"
    end

    test "&nbsp; becomes a plain ASCII space, not a U+00A0" do
      assert Helpers.fix_html_entities("a&nbsp;b") == "a b"
    end

    test "decodes hexadecimal umlaut references" do
      assert Helpers.fix_html_entities("&#xC4;&#xE4;&#xD6;&#xF6;&#xDC;&#xFC;&#xDF;") == "ÄäÖöÜüß"
    end

    test "escapes stray ampersands before decoding entities" do
      assert Helpers.fix_html_entities("Tom & Jerry &auml;") == "Tom &amp; Jerry ä"
    end
  end

  describe "unescape_double_escaped_entities/1" do
    test "collapses one level of over-escaping" do
      assert Helpers.unescape_double_escaped_entities("&amp;quot;Hi&amp;quot;") ==
               "&quot;Hi&quot;"

      assert Helpers.unescape_double_escaped_entities("it&amp;#039;s") == "it&#039;s"
      assert Helpers.unescape_double_escaped_entities("&amp;#x27;") == "&#x27;"
      assert Helpers.unescape_double_escaped_entities("&amp;amp;") == "&amp;"
      assert Helpers.unescape_double_escaped_entities("&amp;lt;b&amp;gt;") == "&lt;b&gt;"
    end

    test "leaves correctly escaped text alone" do
      assert Helpers.unescape_double_escaped_entities("Tom &amp; Jerry") == "Tom &amp; Jerry"
      assert Helpers.unescape_double_escaped_entities("&quot;") == "&quot;"
    end

    test "the decoded title contains a real quote mark" do
      assert feed("<title>&amp;quot;Hi&amp;quot;</title>") |> clean() |> title() == ~s("Hi")
    end
  end

  describe "remove_doctype/1" do
    test "removes an external DTD reference" do
      xml = ~s(<?xml version="1.0"?><!DOCTYPE rss SYSTEM "file:///etc/passwd"><rss/>)

      assert Helpers.remove_doctype(xml) == ~s(<?xml version="1.0"?><rss/>)
    end

    test "removes a public identifier" do
      xml = ~s(<!DOCTYPE rss PUBLIC "-//Netscape//DTD RSS 0.91//EN" "http://x.org/rss.dtd"><rss/>)

      assert Helpers.remove_doctype(xml) == "<rss/>"
    end

    test "removes an internal subset declaring an external entity" do
      xml = ~s(<!DOCTYPE rss [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><rss>&xxe;</rss>)

      cleaned = Helpers.remove_doctype(xml)

      assert cleaned == "<rss>&xxe;</rss>"
      refute cleaned =~ "ENTITY"
    end

    test "leaves a document without DOCTYPE untouched" do
      xml = feed("<title>DOCTYPE</title>")

      assert Helpers.remove_doctype(xml) == xml
    end

    test "a feed with a DTD reference to a missing file parses after cleaning" do
      xml = ~s(<!DOCTYPE rss SYSTEM "/nonexistent/rss.dtd">) <> feed("<title>x</title>")

      assert clean(xml) |> parses?()
    end
  end

  describe "remove_duplicate_xml_declarations/1" do
    test "drops a second declaration in the middle of the feed" do
      raw = feed(~s(<title>a</title><description><?xml version="1.0"?></description>))

      refute parses?(raw)

      cleaned = Helpers.remove_duplicate_xml_declarations(raw)
      assert parses?(cleaned)
      assert length(Regex.scan(~r/<\?xml/, cleaned)) == 1
    end

    test "keeps the first declaration, also after leading whitespace" do
      xml = "\n  " <> feed("<title>a</title>")

      assert Helpers.remove_duplicate_xml_declarations(xml) == xml
    end

    test "drops a lone declaration that is not at the start of the document" do
      xml = ~s(<rss><channel><title>a</title><?xml version="1.0"?></channel></rss>)

      assert Helpers.remove_duplicate_xml_declarations(xml) ==
               "<rss><channel><title>a</title></channel></rss>"
    end

    test "drops several extra declarations" do
      xml = ~s(<?xml version="1.0"?><a><?xml version="1.0"?><b/><?xml version='1.0'?></a>)

      assert Helpers.remove_duplicate_xml_declarations(xml) ==
               ~s(<?xml version="1.0"?><a><b/></a>)
    end

    test "leaves an xml-stylesheet processing instruction alone" do
      xml = ~s(<?xml version="1.0"?><?xml-stylesheet href="a.xsl"?><rss/>)

      assert Helpers.remove_duplicate_xml_declarations(xml) == xml
    end

    test "leaves a feed without any declaration alone" do
      assert Helpers.remove_duplicate_xml_declarations("<rss/>") == "<rss/>"
    end
  end

  describe "fix_encoding/1" do
    test "valid UTF-8 passes through unchanged" do
      assert Helpers.fix_encoding("Grüße – ok") == "Grüße – ok"
    end

    test "decodes Windows-1252 bytes, including the 0x80-0x9F range" do
      # 0x92 is a right single quotation mark in cp1252, a control character in ISO-8859-1
      assert Helpers.fix_encoding(<<"It", 0x92, "s Gr", 0xFC, 0xDF, "e">>) == "It’s Grüße"
    end

    test "a raw 0xA0 byte becomes a plain space after the whole cleanup" do
      raw = feed(<<"<title>a", 0xA0, "b</title>">>)

      assert clean(raw) |> title() == "a b"
    end

    test "the cleaned cp1252 feed parses" do
      raw = feed(<<"<title>It", 0x92, "s</title>">>)

      assert clean(raw) |> parses?()
    end
  end

  describe "remove_comments/1" do
    test "removes single-line and multi-line comments" do
      assert Helpers.remove_comments("a<!-- x -->b<!--\nmulti\nline\n-->c") == "abc"
    end

    test "is not greedy across two comments" do
      assert Helpers.remove_comments("<!-- 1 -->keep<!-- 2 -->") == "keep"
    end
  end

  describe "remove_extra_angle_brackets/1" do
    test "collapses doubled closing brackets" do
      assert Helpers.remove_extra_angle_brackets("<title>a</title>>") == "<title>a</title>"
    end

    test "removes the backspace control character, which is illegal in XML" do
      assert Helpers.remove_extra_angle_brackets("a\bb") == "ab"
    end
  end

  describe "fix_character_code_strings/1" do
    test "replaces the Windows-1252 encoding name, which Erlang does not know" do
      xml = ~s(<?xml version="1.0" encoding="Windows-1252"?><rss/>)

      assert Helpers.fix_character_code_strings(xml) ==
               ~s(<?xml version="1.0" encoding="iso-8859-1"?><rss/>)
    end
  end

  describe "fix_missing_xml_tag/1" do
    test "prepends a declaration when it is missing" do
      assert Helpers.fix_missing_xml_tag("<rss/>") ==
               {:ok, ~s(<?xml version="1.0" encoding="UTF-8"?><rss/>)}
    end

    test "leaves an existing declaration alone" do
      xml = ~s(<?xml version="1.0"?><rss/>)

      assert Helpers.fix_missing_xml_tag(xml) == {:ok, xml}
    end
  end

  describe "to_255/1" do
    test "nil stays nil and short text stays as it is" do
      assert Helpers.to_255(nil) == nil
      assert Helpers.to_255("short") == "short"
      assert Helpers.to_255(String.duplicate("a", 255)) == String.duplicate("a", 255)
    end

    test "cuts long text to 255 bytes" do
      assert Helpers.to_255(String.duplicate("a", 300)) == String.duplicate("a", 255)
    end

    test "never cuts a multi-byte character in half" do
      # 254 ASCII bytes, then a 2-byte "ü" crossing the 255 byte boundary
      cut = Helpers.to_255(String.duplicate("a", 254) <> "üü")

      assert cut == String.duplicate("a", 254)
      assert String.valid?(cut)
    end

    test "stringifies non-binary input instead of crashing" do
      assert Helpers.to_255(:blocked_host) == ":blocked_host"
      assert Helpers.to_255({:error, :nxdomain}) == "{:error, :nxdomain}"
      assert byte_size(Helpers.to_255(%{text: String.duplicate("a", 400)})) <= 255
    end
  end

  describe "scrub/1" do
    test "nil becomes an empty string" do
      assert Helpers.scrub(nil) == ""
    end

    test "plain text passes and unsafe markup is removed" do
      assert Helpers.scrub("plain text") == "plain text"

      scrubbed =
        Helpers.scrub(~s|<p>ok</p><script>alert(1)</script><a href="javascript:x()">l</a>|)

      refute scrubbed =~ "<script"
      refute scrubbed =~ "javascript:"
      assert scrubbed =~ "ok"
    end

    test "mixed content lists are flattened to text" do
      mixed = [
        "text ",
        %{name: :a, attr: [], value: ["more ", %{name: :span, attr: [], value: ["nested"]}]}
      ]

      assert Helpers.scrub(mixed) == "text more nested"
    end

    test "an element map is scrubbed by its value" do
      assert Helpers.scrub(%{name: :description, attr: [], value: ["<b>bold</b>"]}) =~ "bold"
    end

    test "an invalid code point does not raise" do
      assert is_binary(Helpers.scrub("a &#2013265935; <b>b</b>"))
    end
  end

  describe "small helpers" do
    test "boolify/1 accepts exactly the lowercase string yes" do
      assert Helpers.boolify("yes")
      refute Helpers.boolify("Yes")
      refute Helpers.boolify("true")
      refute Helpers.boolify("no")
      refute Helpers.boolify(nil)
    end

    test "deep_merge/2 merges nested maps and lets the right side win otherwise" do
      assert Helpers.deep_merge(%{a: %{b: 1, c: 2}, d: 1, e: [1]}, %{
               a: %{c: 3},
               d: %{x: 1},
               e: [2]
             }) ==
               %{a: %{b: 1, c: 3}, d: %{x: 1}, e: [2]}
    end

    test "md5hash/1 is the upper case hex digest" do
      assert Helpers.md5hash("") == "D41D8CD98F00B204E9800998ECF8427E"
    end

    test "strip_tags/1 removes all markup" do
      assert Helpers.strip_tags("<p>a <b>b</b></p>") == "a b"
    end
  end

  describe "to_naive_datetime/1" do
    @dates [
      # RFC 822 and its usual variations
      {"Mon, 15 Jun 2020 10:00:00 +0200", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 GMT", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00 +0200", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 9:05:00 +0200", ~N[2020-06-15 09:05:00]},
      {"Mon, 15 Jun 2020 10:00:00 0000", ~N[2020-06-15 10:00:00]},
      {"15 Jun 2020 10:00:00 +0200", ~N[2020-06-15 10:00:00]},
      # ISO 8601 / RFC 3339
      {"2020-06-15T10:00:00Z", ~N[2020-06-15 10:00:00]},
      {"2020-06-15T10:00:00+02:00", ~N[2020-06-15 10:00:00]},
      {"2020-06-15T10:00:00.123Z", ~N[2020-06-15 10:00:00]},
      {"2020-06-15T10:00:00", ~N[2020-06-15 10:00:00]},
      {"2020-06-15 10:00:00", ~N[2020-06-15 10:00:00]},
      {"2020-06-15", ~N[2020-06-15 00:00:00]},
      # long names, ordinals and other languages
      {"Monday, 15 June 2020 10:00:00 +0200", ~N[2020-06-15 10:00:00]},
      {"Mon, 15th Jun 2020 10:00:00 +0200", ~N[2020-06-15 10:00:00]},
      {"Sun, 3rd Nov 2019 19:29:11 +0100", ~N[2019-11-03 19:29:11]},
      {"Mo, 15 Juni 2020 10:00:00 +0200", ~N[2020-06-15 10:00:00]},
      {"Sam, 20 Mär 2021 08:30:00 +0100", ~N[2021-03-20 08:30:00]},
      {"mar, 01 mar 2022 12:00:00 +0100", ~N[2022-03-01 12:00:00]},
      # time zone names and typos
      {"Mon, 15 Jun 2020 10:00:00 EST", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 CEST", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 PDT", ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 GTM", ~N[2020-06-15 10:00:00]},
      # upper case names must not be hit by the time zone abbreviations (CT, ET, ...)
      {"MON, 15 OCT 2020 10:00:00 +0200", ~N[2020-10-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 PM", ~N[2020-06-15 22:00:00]},
      # noise around the date
      {~s("Mon, 15 Jun 2020 10:00:00 +0200"), ~N[2020-06-15 10:00:00]},
      {"Mon, 15 Jun 2020 10:00:00 +0200\r\n", ~N[2020-06-15 10:00:00]},
      {"  Mon,  15 Jun 2020 10:00:00 +0200  ", ~N[2020-06-15 10:00:00]},
      {"Sun, 10 Nov 2019 19:29:11 +0100 Nov", ~N[2019-11-10 19:29:11]}
    ]

    for {input, expected} <- @dates do
      test "parses #{inspect(input)}" do
        assert Helpers.to_naive_datetime(unquote(input)) == unquote(Macro.escape(expected))
      end
    end

    test "reads a date out of a nested <time datetime=...> element" do
      nested = %{
        name: :time,
        attr: [datetime: "2026-06-10T01:51:04+02:00"],
        value: ["10 June 2026"]
      }

      assert Helpers.to_naive_datetime(nested) == ~N[2026-06-10 01:51:04]
    end

    test "falls back to the text of a nested element without a datetime attribute" do
      nested = %{name: :time, attr: [], value: ["Mon, 15 Jun 2020 10:00:00 GMT"]}

      assert Helpers.to_naive_datetime(nested) == ~N[2020-06-15 10:00:00]
    end

    test "a date without a year gets the current year" do
      year = Date.utc_today().year

      capture_log(fn ->
        assert %NaiveDateTime{year: ^year, month: 6, day: 15} =
                 Helpers.to_naive_datetime("Mon, 15 Jun 10:00:00 +0200")
      end)
    end

    test "an unparseable date falls back to now instead of raising" do
      capture_log(fn ->
        result = Helpers.to_naive_datetime("not a date at all")

        assert %NaiveDateTime{} = result
        assert abs(NaiveDateTime.diff(NaiveDateTime.utc_now(), result)) < 10
      end)
    end
  end
end
