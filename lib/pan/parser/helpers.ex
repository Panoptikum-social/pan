defmodule Pan.Parser.Helpers do
  import Ecto.Query
  alias Pan.Repo
  alias Pan.Parser.MyDateTime
  require Logger

  @date_formats [
    # RFC 822 — standard RSS/podcast format
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z}",
    # RFC 3339 / ISO 8601 — common in modern feeds
    "{RFC3339z}",
    "{ISO:Extended}",
    "{YYYY}-{0M}-{0D}T{ISOtime} {Z:}",
    "{YYYY}-{0M}-{0D}T{ISOtime}",
    "{YYYY}-{0M}-{0D} {ISOtime} {Z}",
    "{YYYY}-{0M}-{0D} {ISOtime} {Zname}",
    "{YYYY}-{0M}-{0D} {ISOtime}",
    "{YYYY}-{0M}-{0D}",
    # RFC 822 variants
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z:}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Zname}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z} {Zname}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime}{Zname}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} GMT{Z:}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} GMT {Z}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} 0100",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {AM} {Zname}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {AM}",
    "{WDshort} {D} {Mshort} {YYYY} {ISOtime}",
    "{WDshort} {D} {Mshort} {YYYY} 0{ISOtime} {Z}",
    "{WDshort} {D}{Mshort} {YYYY} {ISOtime} {Z}",
    "{WDshort} {D} {Mshort} {YYYY} {h24}:{m} {Z}",
    "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}",
    "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}:{s}{ss}{Z:}",
    "{WDshort} {D} {Mshort} {YYYY} {Z}",
    "{WDshort} {D} {Mshort} {YYYY} GMT",
    "{WDshort} {D} {Mshort} {YYYY}",
    "{WDshort} {0D}-{Mshort}-{YYYY} {ISOtime} {Z}",
    "{WDshort} {0D}-{Mshort}-{YYYY} {ISOtime} {Zname}",
    "{WDshort} {D} {Mshort} {ISOtime} {Zname}",
    # American weekday-first, month before day
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Z}",
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Zname}",
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Zname})",
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Z})",
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {AM}",
    "{WDshort} {Mshort} {D} {YYYY} {ISOtime}",
    "{WDshort} {Mshort} {D} {YYYY} {Z}",
    "{WDshort} {Mshort} {D} {YYYY}",
    "{WDshort} {Mshort} {D} {ISOtime} {Z}",
    "{WDshort}  {Mshort} {D} {YYYY} {ISOtime}",
    # Unusual weekday-prefixed formats
    "{WDshort} {0D}/{0M}/{YYYY} - {h24}:{m}",
    "{WDshort}:{D}:{0M}:{YYYY}: {ISOtime}",
    "{WDshort} {D}.{M}.{YYYY} {ISOtime} {Z}",
    # Day Month Year without weekday
    "{D} {Mshort} {YYYY} {ISOtime} {Z}",
    "{D} {Mshort} {YYYY} {ISOtime} {Zname}",
    "{D} {Mshort} {YYYY} {ISOtime}",
    "{D} {Mshort} {YYYY}",
    "{0D} {Mshort} {YYYY} {ISOtime} {Z}",
    # Month Day Year without weekday
    "{Mshort} {D} {YYYY} {ISOtime} {Zname}",
    "{Mshort} {D} {YYYY} {ISOtime} {Z}",
    "{Mshort} {D} {YYYY} {ISOtime}",
    "{Mshort} {D} {YYYY}",
    "{Mshort} {YYYY}",
    # Numeric-only formats
    "{YYYY}/{M}/{0D}",
    "{YYYY}/{0M}/{0D} {ISOtime}",
    "{0M}/{0D}/{YYYY} {ISOtime} {Zname}",
    "{0M}/{0D}/{YYYY} {ISOtime} {AM} {Z}",
    "{M}/{0D}/{YYYY} {ISOtime} {AM} {Z}",
    "{0M}/{0D}/{YYYY} - {h24}:{m}",
    "{0M}/{0D}/{YYYY} {Zname}",
    "{0M}/{0D}/{YYYY}",
    "{M}/{0D}/{YYYY}",
    "{0D}/{0M}/{YYYY} {ISOtime}",
    "{0D}-{0M}-{YYYY}",
    "{0D}.{0M}.{YYYY}"
  ]

  # Some feeds (buggy podcaster-side software) omit the year entirely, e.g.
  # "Sun Jun 14 16:00:07 GMT". These mirror the RFC 822-ish variants above,
  # minus {YYYY} — Timex parses them fine but defaults the year to 0000, so
  # we detect and overwrite it with a guessed year afterwards (see
  # try_yearless_formats/1).
  @yearless_date_formats [
    "{WDshort} {Mshort} {D} {ISOtime} {Zname}",
    "{WDshort} {Mshort} {D} {ISOtime} {Z}",
    "{WDshort} {Mshort} {D} {ISOtime}",
    "{WDshort} {D} {Mshort} {ISOtime} {Zname}",
    "{WDshort} {D} {Mshort} {ISOtime} {Z}",
    "{WDshort} {D} {Mshort} {ISOtime}",
    "{Mshort} {D} {ISOtime} {Zname}",
    "{Mshort} {D} {ISOtime} {Z}",
    "{Mshort} {D} {ISOtime}"
  ]

  @tz_map %{
    "GMT+1" => "+0100",
    "GMT+2" => "+0200",
    "AEST" => "+1000",
    "AEDT" => "+1100",
    "CEST" => "+0200",
    "NZST" => "+1200",
    "NZDT" => "+1300",
    "BRT" => "-0300",
    "BST" => "+0100",
    "CDT" => "-0500",
    "CMT" => "-0600",
    "CST" => "-0600",
    "EDT" => "-0400",
    "EST" => "-0500",
    "GST" => "+0400",
    "IDT" => "+0300",
    "JST" => "+0900",
    "KST" => "+0900",
    "PCT" => "-0700",
    "PDT" => "-0700",
    "PST" => "-0700",
    "ET" => "-0500",
    "CT" => "-0600"
  }

  @tz_regex Regex.compile!(
              @tz_map
              |> Map.keys()
              |> Enum.sort_by(&byte_size/1, :desc)
              |> Enum.map_join("|", &Regex.escape/1)
            )

  def boolify(explicit) do
    case explicit do
      "yes" -> true
      _ -> false
    end
  end

  # Formatters reference: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
  def to_naive_datetime(feed_date) do
    feed_date =
      feed_date
      |> extract_date_string()
      |> initial_cleanup()

    datetime =
      Enum.find_value(@date_formats, &try_format(feed_date, &1)) ||
        try_yearless_formats(feed_date)

    ensure_naive_in_seconds(datetime, feed_date)
  end

  # Retries against formats without a year, for feeds that omit it entirely.
  # Timex fills in a missing year as 0000, so on a successful parse we swap
  # in a guessed one — there's no better hint available at this point than
  # "current year", which at least keeps recency-sorted episode lists sane.
  defp try_yearless_formats(feed_date) do
    case Enum.find_value(@yearless_date_formats, &try_format(feed_date, &1)) do
      nil ->
        nil

      datetime ->
        Logger.warning("Date missing year, assuming #{Date.utc_today().year}: #{feed_date}")
        %{datetime | year: Date.utc_today().year}
    end
  end

  # Some feeds nest a date inside a child tag instead of giving plain text,
  # e.g. <lastBuildDate><time datetime="2026-06-10T01:51:04+02:00">...</time></lastBuildDate>
  # which the XML parser hands us as %{name: :time, value: [...], attr: [datetime: ...]}.
  defp extract_date_string(feed_date) when is_binary(feed_date), do: feed_date

  defp extract_date_string(%{attr: attr, value: value}) do
    case attr[:datetime] do
      nil -> value |> List.first() |> extract_date_string()
      datetime -> datetime
    end
  end

  def initial_cleanup(feed_date) do
    feed_date
    |> String.replace(",", " ")
    |> String.replace("p.m.", "")
    |> String.replace(". ", " ")
    |> String.replace("  ", " ")
    |> String.replace("\"", "")
    |> String.replace("ٍ", "")
    |> String.replace("~", "")
    |> String.replace("\r", "")
    |> String.replace("\t", " ")
    |> String.replace("\n", "")
    |> fix_time()
    |> String.replace(~r/(\d{4}) \1/, "\\1")
    |> replace_first_second_third_fourth()
    |> replace_long_month_names()
    |> replace_long_week_days()
    |> String.replace("  ", " ")
    |> String.trim()
    |> fix_timezones()
  end

  def ensure_naive_in_seconds(datetime, feed_date) do
    case datetime do
      naive = %NaiveDateTime{} ->
        naive
        |> NaiveDateTime.truncate(:second)

      datetime = %DateTime{} ->
        datetime
        |> DateTime.to_naive()
        |> NaiveDateTime.truncate(:second)

      _ ->
        # Unparseable date: don't let it blow up the whole feed import over
        # one bad episode — fall back to "now", same as the already-existing
        # convention for episodes with no pubDate tag at all.
        Logger.warning(
          "Error in date parsing [#{feed_date}] -> [#{inspect(datetime)}], using now()"
        )

        MyDateTime.now()
    end
  end

  def try_format(feed_date, format) do
    case Timex.parse(feed_date, format) do
      {:ok, datetime} -> datetime
      {:error, _} -> nil
    end
  end

  def fix_time(datetime) do
    # add missing minutes
    datetime = Regex.replace(~r/ (\d\d):(\d\d) /, datetime, " \\1:\\2:00 ")

    # add missing leading 0 for hours
    Regex.replace(~r/ (\d):/, datetime, " 0\\1:")
  end

  def replace_first_second_third_fourth(datetime) do
    datetime
    |> String.replace(~r/(\d)st/i, "\\1")
    |> String.replace(~r/(\d)nd/i, "\\1")
    |> String.replace(~r/(\d)rd/i, "\\1")
    |> String.replace(~r/(\d)th/i, "\\1")
  end

  def replace_long_month_names(datetime) do
    datetime
    # the next line captures the french "mar, 01 mar whatever" pattern, where mar stands for tuesday and march
    |> String.replace(~r/mar(.+)mar/i, "Tue\\1Mar", global: false)
    |> String.replace(~r/janr?u?r?a?r?y?/i, "Jan")
    |> String.replace(~r/f[aeé][brv][rv]?u?a?r?y?/iu, "Feb")
    |> String.replace(~r/m[aä]rc?[zh]?/iu, "Mar")
    |> String.replace(~r/a[pvb]r?i?l?/i, "Apr")
    |> String.replace(~r/m[a][iy]/i, "May")
    |> String.replace(~r/jui?n[ieg]?/i, "Jun")
    |> String.replace(~r/jui?[l1][iy]?/i, "Jul")
    |> String.replace(~r/a[uo]?[gû][ou]?s?t?/ui, "Aug")
    |> String.replace(~r/s[ep]p?t?e?m?b?e?r?/i, "Sep")
    |> String.replace(~r/o[uck]to?b?e?r?/i, "Oct")
    |> String.replace(~r/no[vc]e?m?e?b?e?r?/i, "Nov")
    |> String.replace(~r/d[eéi][vcsz][e]?m?b?[re]?[ro]?/iu, "Dec")
    |> String.replace(
      ~r/\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b/,
      "\\1"
    )
    |> String.replace(~r/^Mar( .+\b(?:Jan|Feb|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b)/, "Tue\\1")
    # drop a stray trailing month name repeating one already used earlier,
    # e.g. "Sun 10 Nov 2019 19:29:11 Nov" -> "Sun 10 Nov 2019 19:29:11"
    |> String.replace(
      ~r/\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b(.*)\s\1\s*$/,
      "\\1\\2"
    )
  end

  def replace_long_week_days(datetime) do
    # Saturday and Tuesday would interfere, if ordered
    datetime
    |> String.replace(~r/sa[sm]?t?u?r?d?a?y?/i, "Sat")
    |> String.replace(~r/m[oå]n?d?a?y?/iu, "Mon")
    |> String.replace(~r/t[ui][er]?s?[du]?[an]?y?/i, "Tue")
    |> String.replace("Di", "Tue")
    |> String.replace("tor", "Tue")
    |> String.replace(~r/we[db]?[né]?e?s?d?a?y?/iu, "Wed")
    |> String.replace(~r/mié/iu, "Wed")
    |> String.replace("MWed", "Wed")
    |> String.replace("mer", "Wed")
    |> String.replace(~r/mie?/i, "Wed")
    |> String.replace(~r/thu?[er]?s?d?a?y?/i, "Thu")
    |> String.replace(~r/do/i, "Thu")
    |> String.replace(~r/j[eu][eu]/i, "Thu")
    |> String.replace(~r/ven/i, "Fri")
    |> String.replace(~r/f[ir][rei]?d?a?y?/i, "Fri")
    |> String.replace(~r/s[ou]n?d?a?y?/i, "Sun")
    |> String.replace(~r/dim/i, "Sun")
    |> String.replace(~r/lun/i, "Mon")
  end

  def fix_timezones(datetime) do
    datetime
    |> String.replace(" 0000", " +0000")
    |> String.replace("GTM", "GMT")
    |> String.replace("-0001", "2016")
    |> String.replace(@tz_regex, fn match -> Map.fetch!(@tz_map, match) end)
  end

  def fix_missing_xml_tag(xml) do
    xml =
      if String.starts_with?(xml, ["<?xml"]) do
        xml
      else
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" <> xml
      end

    {:ok, xml}
  end

  # Deep merging maps
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, %{} = left, %{} = right) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end

  # export feed urls
  def feed_urls do
    Repo.all(from(f in PanWeb.Feed, select: [f.self_link_url]))
  end

  def remove_comments(xml) do
    # U ... non-greedy, s ... . matches newlines as well
    Regex.replace(~r/<!--.*-->/Us, xml, "")
  end

  def normalize_nbsp(xml) do
    # A literal U+00A0 (non-breaking space) byte can already be sitting in
    # the raw feed (common when show-note HTML was pasted out of a word
    # processor) rather than arriving via a decoded &nbsp; entity. Unlike
    # a regular space, xmerl's tokenizer doesn't treat U+00A0 as
    # whitespace, so one landing right after a tag name or attribute value
    # — where a regular feed would just have an ordinary space separating
    # attributes — makes xmerl try to scan a new attribute/element NAME
    # starting at that byte and fatal with :invalid_name (seen live: a
    # stray "\u00A0text" this way). Normalize to a plain space everywhere,
    # same trade-off fix_html_entities already makes for the &nbsp; entity
    # itself.
    String.replace(xml, " ", " ")
  end

  def remove_doctype(xml) do
    # A <!DOCTYPE ... SYSTEM "..."> / PUBLIC "..." "..."> declaration makes
    # xmerl try to fetch that external DTD before it parses anything else
    # (xmerl_scan.erl's fetch_DTD/2, called unconditionally, validation
    # option or not). By default that's a local file read resolved against
    # the app's cwd, or — for a "http://..." system literal — an actual
    # outbound request, so a malicious feed could use it to probe the
    # filesystem or make this app fetch arbitrary URLs (fetch_URI/2). On
    # top of that, a DTD path that doesn't exist currently crashes the
    # whole scan with an unhandled CaseClauseError inside xmerl itself
    # (fetch_DTD/2 has no clause for {:error, :enoent} on OTP 28's xmerl
    # 2.1.9) instead of a catchable {:fatal, _} exit. RSS/Atom feeds have
    # no legitimate use for a custom DOCTYPE, so just drop it before it
    # ever reaches Quinn/xmerl.
    Regex.replace(~r/<!DOCTYPE[^\[>]*(\[[^\]]*\])?[^>]*>/, xml, "")
  end

  def remove_duplicate_xml_declarations(xml) do
    # An XML declaration (<?xml version="..." ...?>) is only legal as the
    # very first thing in a document. If a second one shows up further
    # down — feeds concatenated by a broken proxy/CDN, or an item embedding
    # a raw XML snippet in its body instead of escaping/CDATA-wrapping it —
    # xmerl doesn't recover from it: any processing instruction whose
    # target starts with "xml" other than the well-known "xml-stylesheet"
    # fatals with :invalid_target_name (xmerl_scan.erl's
    # scan_wellknown_pi/3), taking the whole parse down with it. Keep the
    # first (real) declaration and drop any later ones. Matching on
    # "version=" (rather than just "<?xml") deliberately leaves a
    # legitimate <?xml-stylesheet ...?> PI alone.
    #
    # A declaration is only "real" if it's the very first thing in the
    # document (only leading whitespace allowed before it) — a feed with
    # no leading declaration at all, but a stray one embedded further down
    # (e.g. raw XML pasted unescaped into an item description), has
    # exactly one regex match and it is NOT legitimate. Treating "the
    # first match found" as automatically real (rather than checking its
    # position) left that case untouched and still fataling with
    # :invalid_target_name (seen live).
    regex = ~r/<\?xml\s+version\s*=[^?]*\?>/

    case Regex.run(regex, xml, return: :index) do
      nil ->
        xml

      [{start, len}] ->
        if String.trim_leading(binary_part(xml, 0, start)) == "" do
          keep_through = start + len
          head = binary_part(xml, 0, keep_through)
          tail = binary_part(xml, keep_through, byte_size(xml) - keep_through)
          head <> Regex.replace(regex, tail, "")
        else
          Regex.replace(regex, xml, "")
        end
    end
  end

  def fix_character_code_strings(xml) do
    # Erlang does not know of 1252, that's the best we can do for now
    Regex.replace(~r/Windows-1252/Us, xml, "iso-8859-1")
  end

  def remove_extra_angle_brackets(xml) do
    xml = Regex.replace(~r/>>/Us, xml, ">")
    Regex.replace(~r//Us, xml, "")
  end

  def fix_html_entities(xml) do
    xml
    |> unescape_double_escaped_entities()
    |> escape_stray_ampersands()
    |> String.replace("&#xC4;", "Ä")
    |> String.replace("&#xE4;", "ä")
    |> String.replace("&#xD6;", "Ö")
    |> String.replace("&#xF6;", "ö")
    |> String.replace("&#xDC;", "Ü")
    |> String.replace("&#xFC;", "ü")
    |> String.replace("&#xDF;", "ß")
    # A bare XML document only knows 5 predefined entities (amp/lt/gt/apos/
    # quot) — HTML-authored named entities like &nbsp; or &auml; leak in
    # constantly from feed producers that treat their description field as
    # HTML, and xmerl fatals on them (:unknown_entity_ref) since there's no
    # DTD declaring what they mean. Decode to the real character, same as
    # the numeric refs above, rather than just dropping/erroring on it.
    # Covers &nbsp; plus the German umlaut/eszett entities, since this is a
    # German-language podcast platform and those are what's actually shown
    # up so far — extend as further named entities surface.
    |> String.replace("&nbsp;", " ")
    |> String.replace("&auml;", "ä")
    |> String.replace("&ouml;", "ö")
    |> String.replace("&uuml;", "ü")
    |> String.replace("&Auml;", "Ä")
    |> String.replace("&Ouml;", "Ö")
    |> String.replace("&Uuml;", "Ü")
    |> String.replace("&szlig;", "ß")
    |> String.replace("&hellip;", "…")
    |> String.replace("&ndash;", "–")
    |> String.replace("&mdash;", "—")
  end

  # Some feed producers double-encode their own output (e.g. re-escaping an
  # already-escaped title when it's edited through their CMS), leaving
  # things like &amp;quot; or &amp;#039; in the raw XML. A conformant
  # single-pass XML parser only decodes &amp; -> &, so &amp;quot; ends up
  # stored as the literal text "&quot;" instead of an actual quote mark.
  # Collapse one level of over-escaping for the 5 standard XML entities and
  # numeric character references before parsing, so the real decode pass
  # can finish the job.
  def unescape_double_escaped_entities(xml) do
    Regex.replace(~r/&amp;(quot|apos|amp|lt|gt|#\d+|#x[0-9A-Fa-f]+);/, xml, "&\\1;")
  end

  # A bare "&" that isn't the start of a real entity/character reference is
  # invalid XML — text pasted from elsewhere ("Tom & Jerry", a URL's query
  # string, obfuscated JS show-note markup like "&(_0x1a2b...") is full of
  # these. xmerl fatals with :invalid_name as soon as it tries to scan the
  # "name" following the "&" and finds something that can't start one
  # (seen live: {:invalid_name, ~c"&(_0x1"}). Escape any "&" not
  # plausibly starting a real reference (a letter/underscore/colon for a
  # named one, or "#" for a numeric one) to "&amp;" before anything else
  # in fix_html_entities/1 runs — letter-led text like "nbsp"/"auml" is
  # left alone here so the decode passes below still see it.
  def escape_stray_ampersands(xml) do
    Regex.replace(~r/&(?![a-zA-Z_:#])/, xml, "&amp;")
  end

  def fix_encoding(xml) do
    # Windows-1252 is a strict superset of ISO-8859-1 for every byte except
    # 0x80-0x9F: ISO-8859-1 leaves those as unprintable C1 control
    # characters (themselves invalid XML characters, so xmerl fatals with
    # :bad_character on them — seen live: byte 146/0x92, a right single
    # quotation mark), while cp1252 correctly maps that range to real
    # typographic punctuation (curly quotes, en/em dash, ellipsis, €, ...).
    # Genuinely ISO-8859-1 content decodes identically either way, so
    # there's no downside to assuming the more common cp1252 here.
    if String.valid?(xml), do: xml, else: :iconv.convert("WINDOWS-1252", "utf-8", xml)
  end

  def to_255(nil), do: nil

  def to_255(text) when is_binary(text) do
    if byte_size(text) > 255 do
      <<head::binary-size(255), _::binary>> = text
      trim_incomplete_codepoint(head)
    else
      text
    end
  end

  # Callers regularly pass this an {:error, reason} tuple's raw reason
  # straight through as an error "message" (e.g. SsrfGuard.check/1's
  # {:error, :blocked_host}) rather than a string — byte_size/1 on
  # anything else raises ArgumentError, which is exactly the kind of
  # crash-in-the-crash-recorder this function exists to prevent (see
  # PanWeb.Podcast.record_metadata_refresh_failure/2's last_error_message,
  # crashed live on this). Same fallback idiom as PanWeb.Journal.log/1's
  # stringify/1.
  def to_255(other), do: other |> inspect() |> to_255()

  defp trim_incomplete_codepoint(bin) do
    if String.valid?(bin),
      do: bin,
      else: trim_incomplete_codepoint(:binary.part(bin, 0, byte_size(bin) - 1))
  end

  def mark_if_deleted(changeset) do
    if changeset.__meta__.state == :deleted do
      changeset
      |> Map.put(:deleted, true)
      |> Map.put(:created, false)
    else
      changeset
      |> Map.put(:created, true)
      |> Map.put(:deleted, false)
    end
  end

  def scrub(value) when is_nil(value), do: ""

  def scrub(value) when is_binary(value) do
    try do
      HtmlSanitizeEx.Scrubber.BasicHTMLReduced.sanitize(value)
    rescue
      # mochiweb raises for invalid Unicode codepoints (e.g. &#2013265935;) —
      # RuntimeError on older mochiweb, FunctionClauseError in :mochiutf8
      # since the mochiweb 3.5.0 bump for OTP 28 (see mix.lock)
      _error in [RuntimeError, FunctionClauseError] ->
        String.replace(value, ~r/<[^>]+>/, "")
    end
  end

  # Mixed content, e.g. <description>text<a href="...">more text<span>...</span></a></description>
  # parses into a list of binaries interleaved with nested element maps. Flatten it all
  # down to plain text before handing it back to scrub/1 for sanitizing.
  def scrub(value) when is_list(value) do
    value
    |> flatten_to_string()
    |> scrub()
  end

  def scrub(value) do
    value.value
    |> scrub()
  end

  # Quinn trims every text node, so the whitespace around nested elements is
  # already gone; joining with a space keeps the words apart.
  def flatten_to_string(value) when is_binary(value), do: value

  def flatten_to_string(value) when is_list(value) do
    value
    |> Enum.map(&flatten_to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  def flatten_to_string(%{value: value}), do: flatten_to_string(value)
  def flatten_to_string(_value), do: ""

  def strip_tags(value) do
    HtmlSanitizeEx.strip_tags(value)
  end

  def md5hash(xml) do
    :crypto.hash(:md5, xml)
    |> Base.encode16()
  end
end
