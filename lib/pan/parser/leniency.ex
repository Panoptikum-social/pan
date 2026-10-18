defmodule Pan.Parser.Leniency do
  @moduledoc """
  What Panoptikum reads in a feed although it isn't standard, for the feed
  check page ("Panoptikum reads this anyway"): the XML repairs
  `Pan.Parser.RssFeed.clean_xml/1` makes, and dates in other formats than
  RFC 822.

  Standard constructs the clean-up touches as well (comments, a DOCTYPE,
  non-breaking spaces, numeric character references, ">>" in text) are not
  reported. Comments and CDATA sections are left out of the search, as
  anything goes inside them.
  """

  alias Pan.Parser.{Helpers, RssFeed}

  @examples 3
  @context_bytes 25

  @double_escaped ~r/&amp;(quot|apos|amp|lt|gt|#\d+|#x[0-9A-Fa-f]+);/
  @stray_ampersand ~r/&(?![a-zA-Z_:#])/
  @stray_less_than ~r/<(?=\s)/
  @xml_declaration ~r/<\?xml\s+version\s*=[^?]*\?>/
  @backspace ~r/\x08/

  @rfc2822_date ~r/^(?:[A-Za-z]{3},\s*)?\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4}\s+\d{2}:\d{2}(?::\d{2})?\s+(?:[+-]\d{4}|[A-Za-z]{1,5})$/
  # dc:date is W3CDTF, a profile of ISO 8601
  @w3cdtf_date ~r/^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:\d{2}))?)?)?$/
  # The tags Pan.Parser.Analyzer reads dates from.
  @date_tags [
    :lastBuildDate,
    :"dc:date",
    :pubdate,
    :pubDate,
    :PubDate,
    :lastPubDate,
    :"itunes:pubDate",
    :pubDateShort
  ]

  @doc """
  `%{xml: [repair], dates: [date_group]}` for a feed's raw XML, where a
  repair is `%{label: String.t(), count: integer, examples: [String.t()]}`
  and a date group `%{kind: atom, count: integer, example: String.t(), read_as: String.t()}`.
  """
  def report(feed_xml) do
    text = Helpers.fix_encoding(feed_xml)
    searchable = text |> Helpers.remove_comments() |> remove_cdata()

    %{xml: xml_repairs(feed_xml, text, searchable), dates: dates(feed_xml)}
  end

  ## XML

  defp xml_repairs(feed_xml, text, searchable) do
    entities = Regex.compile!(Enum.map_join(Helpers.html_entities(), "|", &Regex.escape/1))

    [
      encoding(feed_xml),
      found(
        "The XML declaration names the encoding Windows-1252, which the XML parser " <>
          "doesn't know; Panoptikum reads it as ISO-8859-1.",
        ~r/Windows-1252/,
        text
      ),
      found(
        "HTML entities that XML doesn't know (such as &nbsp; or &auml;); Panoptikum " <>
          "replaces them with the characters they stand for.",
        entities,
        searchable
      ),
      found(
        "A bare \"&\" that doesn't start an entity (it should be written &amp; or put " <>
          "in a CDATA section).",
        @stray_ampersand,
        searchable
      ),
      found(
        "A \"<\" followed by a space in text (it should be written &lt; or put in a CDATA section).",
        @stray_less_than,
        searchable
      ),
      found(
        "Entities escaped twice, such as &amp;quot; for a quotation mark: apps show " <>
          "\"&quot;\" literally. Panoptikum undoes one level.",
        @double_escaped,
        searchable
      ),
      second_declaration(searchable),
      found(
        "Backspace control characters, which aren't allowed in XML; Panoptikum removes them.",
        @backspace,
        text
      )
    ]
    |> Enum.reject(&(&1.count == 0))
  end

  # Not UTF-8 is only a problem when the feed claims UTF-8, or declares no
  # encoding at all (which means UTF-8).
  defp encoding(feed_xml) do
    declared =
      case Regex.run(~r/<\?xml[^>]*encoding\s*=\s*["']([^"']+)["']/i, feed_xml) do
        [_, encoding] -> String.downcase(encoding)
        nil -> "utf-8"
      end

    %{
      label:
        "The feed is declared as UTF-8 (or declares no encoding, which means UTF-8) but " <>
          "isn't valid UTF-8; Panoptikum reads it as Windows-1252.",
      count: if(declared in ["utf-8", "utf8"] and not String.valid?(feed_xml), do: 1, else: 0),
      examples: []
    }
  end

  defp second_declaration(searchable) do
    matches = Regex.scan(@xml_declaration, searchable, return: :index)
    leading = if Regex.match?(~r/^\s*<\?xml\s/, searchable), do: 1, else: 0

    %{
      label:
        "A second <?xml ...?> declaration inside the document (only one, at the very " <>
          "start, is allowed); Panoptikum removes it.",
      count: max(length(matches) - leading, 0),
      examples:
        matches
        |> Enum.drop(leading)
        |> Enum.take(@examples)
        |> Enum.map(&snippet(searchable, &1))
    }
  end

  defp found(label, regex, text) do
    matches = Regex.scan(regex, text, return: :index)

    %{
      label: label,
      count: length(matches),
      examples: matches |> Enum.take(@examples) |> Enum.map(&snippet(text, &1))
    }
  end

  defp snippet(text, [{start, length} | _groups]) do
    from = max(start - @context_bytes, 0)
    to = min(start + length + @context_bytes, byte_size(text))

    text
    |> binary_part(from, to - from)
    |> String.replace_invalid("")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> then(&"…#{&1}…")
  end

  defp remove_cdata(text), do: Regex.replace(~r/<!\[CDATA\[.*?\]\]>/s, text, "")

  ## Dates

  defp dates(feed_xml) do
    case feed_xml |> RssFeed.clean_xml() |> RssFeed.xml_to_map() do
      {:ok, tree} ->
        tree
        |> date_values()
        |> Enum.reject(&standard_date?/1)
        |> Enum.map(fn {_tag, value} -> value end)
        |> Enum.group_by(&date_kind/1)
        |> Enum.map(fn {kind, [example | _] = values} ->
          %{kind: kind, count: length(values), example: example, read_as: read_as(kind, example)}
        end)
        |> Enum.sort_by(&{kind_order(&1.kind), -&1.count})

      {:error, _reason} ->
        []
    end
  end

  defp date_values(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &date_values/1)

  defp date_values(%{name: name, value: [value]}) when name in @date_tags and is_binary(value),
    do: [{name, String.trim(value)}]

  defp date_values(%{value: value}), do: date_values(value)
  defp date_values(_text), do: []

  defp standard_date?({:"dc:date", value}), do: value =~ @w3cdtf_date
  defp standard_date?({_tag, value}), do: value =~ @rfc2822_date

  # :yearless and :unreadable stay as they are, every other format is one
  # group of its own.
  defp date_kind(value) do
    case Helpers.date_format(value) do
      {:format, format} -> {:format, format}
      other -> other
    end
  end

  defp read_as(:unreadable, _example), do: "the time of the import"
  defp read_as(_kind, example), do: example |> Helpers.to_naive_datetime() |> to_string()

  defp kind_order(:unreadable), do: 0
  defp kind_order(:yearless), do: 1
  defp kind_order(_format), do: 2
end
