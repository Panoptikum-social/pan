defmodule Pan.Parser.Helpers do
  use Pan.Web, :controller
  use Timex
  require Logger

  def boolify(explicit) do
    case explicit do
      "yes" ->
        true
      _ ->
        false
    end
  end


  def inspect(argument) do
    IO.puts "\n\e[33m === Debugger <<<\e[0m"
    IO.inspect argument
    IO.puts "\n\e[33m >>> Debugger ===\e[0m"
  end


  def to_naive_datetime(feed_date) do
    feed_date = feed_date
                |> String.replace("  ", " ")
                |> fix_time()
                |> replace_long_month_names()
                |> replace_long_week_days

    # Formatters reference:
    # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
    datetime = try_format(feed_date, "{RFC1123}") ||
               try_format(feed_date, "{ISO:Extended}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Z}") ||
               try_format(feed_date, "{0D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{WDshort},{D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{WDshort} {D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY}, {ISOtime} {Zname}") ||
               try_format(feed_date, "{WDfull}, {D} {Mshort} {YYYY} {ISOtime} {Z}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime} {Zname}") ||
               try_format(feed_date, "{0M}/{0D}/{YYYY} - {h24}:{m}") ||
               try_format(feed_date, "{WDshort}, {D} {Mshort} {YYYY}") ||
               try_format(feed_date, "{Mshort} {D} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{D} {Mshort} {YYYY} {ISOtime}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}") ||
               try_format(feed_date, "{RFC1123} {Zname}")

    if datetime do
      Timex.to_naive_datetime(datetime)
    else
      Logger.error "Error in date parsing: " <> feed_date
      raise "Error in date parsing"
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


  def replace_long_month_names(datetime) do
    datetime
    |> String.replace("January",   "Jan")
    |> String.replace("February",  "Feb")
    |> String.replace("March",     "Mar")
    |> String.replace("April",     "Apr")
    |> String.replace("June",      "Jun")
    |> String.replace("July",      "Jul")
    |> String.replace("August",    "Aug")
    |> String.replace("September", "Sep")
    |> String.replace("October",   "Oct")
    |> String.replace(" Okt ",     " Oct ")
    |> String.replace(" oct ",     " Oct ")
    |> String.replace(" Dez ",     " Dec ")
    |> String.replace(" Febr ",    " Feb ")
    |> String.replace(" Noc ",    " Nov ")
    |> String.replace(" Set ",    " Sep ")
    |> String.replace(" Sept ",    " Sep ")
    |> String.replace(" Dic ",    " Dec ")
    |> String.replace(" dec ",    " Dec ")
    |> String.replace("November",  "Nov")
    |> String.replace("December",  "Dec")
  end


  def replace_long_week_days(datetime) do
    datetime
    |> String.replace("Wedn,", "Wed,")
    |> String.replace("Thurs,","Thu,")
    |> String.replace("Thur,","Thu,")
    |> String.replace("Mo,",  "Mon,")
    |> String.replace("mån,", "Mon,")
    |> String.replace("Di,",  "Tue,")
    |> String.replace("Tus,",  "Tue,")
    |> String.replace("Tues,",  "Tue,")
    |> String.replace("Weds,",  "Wed,")
    |> String.replace("tor,", "Tue,")
    |> String.replace("Mi,",  "Wed,")
    |> String.replace("Do,",  "Thu,")
    |> String.replace("Fr,",  "Fri,")
    |> String.replace("Sa,",  "Sat,")
    |> String.replace("So,",  "Sun,")
    |> String.replace("Son,", "Sun,")
    |> String.replace("TueSun,", "Sun,")
    |> String.replace("ٍ", "")
    |> String.replace("NZDT", "+1300")
    |> String.replace("NZST", "+1200")
    |> String.replace("AEST", "EST")
    |> String.replace("-0001", "2016")
    |> String.replace("KST", "+0900")
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

  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end


# export feed urls
  def feed_urls do
    urls = Repo.all(from f in Pan.Feed, select: [f.self_link_url])
    for url <- urls do
      IO.puts url
    end
  end


  def remove_comments(xml) do
    # U ... non-greedy, s ... . matches newlines as well
    Regex.replace(~r/<!--.*-->/Us, xml, "")
  end


  def remove_extra_angle_brackets(xml) do
    xml = Regex.replace(~r/>>/Us, xml, ">")
    Regex.replace(~r//Us, xml, "")
  end
end