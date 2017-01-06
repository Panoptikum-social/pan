defmodule Pan.Parser.Helpers do
  use Pan.Web, :controller
  use Timex

  def boolify(explicit) do
    case explicit do
      "yes" ->
        true
      _ ->
        false
    end
  end


  def to_ecto_datetime(feed_date) do
    feed_date = feed_date
                |> fix_time()
                |> replace_long_month_names()
                |> replace_long_week_days

    datetime = try_format(feed_date, "{RFC1123}") ||
               try_format(feed_date, "{ISO:Extended}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D}") ||
               try_format(feed_date, "{YYYY}-{0M}-{0D} {ISOtime} {Z}")

    unless datetime do
      IO.puts feed_date
      IO.puts "==============="
      raise "Error in date parsing"
    end

    erltime = Timex.to_erl(datetime)
    # why can't I pipe here?
    Ecto.DateTime.from_erl(erltime)
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
    datetime = Regex.replace(~r/ (\d):/, datetime, " 0\\1:")
    # add missing day of the week
    # Regex.replace(~r/^(\d)/, datetime, "Mon, \\1")
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
    |> String.replace(" Okt ",   " Oct ")
    |> String.replace(" Dez ",   " Dec ")
    |> String.replace("November",  "Nov")
    |> String.replace("December",  "Dec")
  end

  def replace_long_week_days(datetime) do
    datetime
    |> String.replace("Wedn", "Wed")
    |> String.replace("Thurs","Thu")
    |> String.replace("Thur","Thu")
    |> String.replace("Mo,",  "Mon,")
    |> String.replace("mån,", "Mon,")
    |> String.replace("Di,",  "Tue,")
    |> String.replace("tor,", "Tue,")
    |> String.replace("Mi,",  "Wed,")
    |> String.replace("Do,",  "Thu,")
    |> String.replace("Fr,",  "Fri,")
    |> String.replace("Sa,",  "Sat,")
    |> String.replace("So,",  "Sun,")
    |> String.replace("Son,", "Sun,")
    |> String.replace("ٍ", "")
    |> String.replace("NZDT", "+1300")
    |> String.replace("NZST", "+1200")
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
    Regex.replace(~r/>>/Us, xml, ">")
    Regex.replace(~r//Us, xml, "")
  end
end