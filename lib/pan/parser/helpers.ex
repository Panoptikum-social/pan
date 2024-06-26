defmodule Pan.Parser.Helpers do
  import Ecto.Query
  alias Pan.Repo
  require Logger

  def boolify(explicit) do
    case explicit do
      "yes" -> true
      _ -> false
    end
  end

  def to_naive_datetime(feed_date) do
    feed_date = initial_cleanup(feed_date)

    # Formatters reference:
    # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
    datetime =
      try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} 0{ISOtime} {Z}") ||
        try_format(feed_date, "{WDshort} {D}{Mshort} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z} {Zname}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m} {Z}") ||
        try_format(feed_date, "{ISO:Extended}") ||
        try_format(feed_date, "{WDshort}  {Mshort} {D} {YYYY} {ISOtime}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {h24}:{m}:{s}{ss}{Z:}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} 0100") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} GMT{Z:}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} GMT {Z}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {AM} {Zname}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {AM}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Z:}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {ISOtime} {Zname}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime}{Zname}") ||
        try_format(feed_date, "{WDshort} {0D}/{0M}/{YYYY} - {h24}:{m}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {Z}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY}") ||
        try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} GMT") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {ISOtime} {Z}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Zname})") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} GMT{Z} ({Z})") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {AM}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Zname}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {ISOtime}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY} {Z}") ||
        try_format(feed_date, "{WDshort} {Mshort} {D} {YYYY}") ||
        try_format(feed_date, "{WDshort}:{D}:{0M}:{YYYY}: {ISOtime}") ||
        try_format(feed_date, "{WDshort} {D}.{M}.{YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime} {Zname}") ||
        try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime}") ||
        try_format(feed_date, "{Mshort} {D} {YYYY}") ||
        try_format(feed_date, "{Mshort} {YYYY}") ||
        try_format(feed_date, "{0D} {Mshort} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{0M}/{0D}/{YYYY} - {h24}:{m}") ||
        try_format(feed_date, "{0M}/{0D}/{YYYY} {ISOtime} {Zname}") ||
        try_format(feed_date, "{0M}/{0D}/{YYYY} {Zname}") ||
        try_format(feed_date, "{0M}/{0D}/{YYYY}") ||
        try_format(feed_date, "{M}/{0D}/{YYYY}") ||
        try_format(feed_date, "{YYYY}/{M}/{0D}") ||
        try_format(feed_date, "{0D}/{0M}/{YYYY} {ISOtime}") ||
        try_format(feed_date, "{0D}-{0M}-{YYYY}") ||
        try_format(feed_date, "{0D}.{0M}.{YYYY}") ||
        try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
        try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Z}") ||
        try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime}") ||
        try_format(feed_date, "{D} {Mshort} {YYYY}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Z}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Zname}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D}T{ISOtime}") ||
        try_format(feed_date, "{RFC3339z}") ||
        try_format(feed_date, "{YYYY}-{0M}-{0D}T{ISOtime} {Z:}") ||
        try_format(feed_date, "{YYYY}/{0M}/{0D} {ISOtime}")

    ensure_naive_in_seconds(datetime, feed_date)
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
        Logger.error("Error in date parsing: " <> feed_date)
        raise "Error in date parsing [#{feed_date}] -> [#{datetime}]"
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
    |> String.replace("BRT", "-0300")
    |> String.replace("AEST", "+1000")
    |> String.replace("CEST", "+0200")
    |> String.replace("AEDT", "+1100")
    |> String.replace("NZST", "+1200")
    |> String.replace("NZDT", "+1300")
    |> String.replace("EST", "-0500")
    |> String.replace("CDT", "-0500")
    |> String.replace("EDT", "-0400")
    |> String.replace("CST", "-0600")
    |> String.replace("CMT", "-0600")
    |> String.replace("PST", "-0700")
    |> String.replace("PDT", "-0700")
    |> String.replace("PCT", "-0700")
    |> String.replace("GMT+1", "+0100")
    |> String.replace("BST", "+0100")
    |> String.replace("IDT", "+0300")
    |> String.replace("GST", "+0400")
    |> String.replace("KST", "+0900")
    |> String.replace("JST", "+0900")
    |> String.replace("GTM", "GMT")
    |> String.replace("GMT+2", "+0200")
    |> String.replace("-0001", "2016")
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
    |> String.replace("& ", "&amp; ")
    |> String.replace("&#xC4;", "Ä")
    |> String.replace("&#xE4;", "ä")
    |> String.replace("&#xD6;", "Ö")
    |> String.replace("&#xF6;", "ö")
    |> String.replace("&#xDC;", "Ü")
    |> String.replace("&#xFC;", "ü")
    |> String.replace("&#xDF;", "ß")
  end

  def fix_encoding(xml) do
    if String.valid?(xml), do: xml, else: :iconv.convert("ISO-8859-1", "utf-8", xml)
  end

  def to_255(text) do
    if text && byte_size(text) > 255 do
      chars =
        text
        |> binary_part(0, 255)
        |> String.length()

      String.slice(text, 0, chars - 2)
    else
      text
    end
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
    # i -> case insensive; s -> dotall, dot matches also newlines; U -> ungreedy
    String.replace(value, ~r/<script.*<\/script>/isU, "")
    |> HtmlSanitizeEx2.basic_html_reduced()
  end

  def scrub(value) do
    value.value
    |> to_string
    |> scrub()
  end

  def strip_tags(value) do
    HtmlSanitizeEx.strip_tags(value)
  end

  def md5hash(xml) do
    :crypto.hash(:md5, xml)
    |> Base.encode16()
  end
end
