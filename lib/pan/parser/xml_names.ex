defmodule Pan.Parser.XmlNames do
  @moduledoc """
  Guards xmerl (under Quinn) against atom table exhaustion. xmerl turns every
  element, attribute and processing instruction name into an atom, and atoms
  are never freed, so a document with hundreds of thousands of unique names
  (an uploaded OPML, a feed someone controls) would crash the whole VM at the
  atom limit (~1 million).

  Real feeds use 40 to 70 distinct names (measured 2026-10-19 on eleven big
  feeds from Anchor, Acast, Captivate, Libsyn, Megaphone, RedCircle,
  Simplecast, Transistor, ART19, a Podlove publisher and cba), OPML files far
  fewer, so a document with more than `@max` is refused unparsed.
  """

  @max 500

  @doc """
  `:ok`, or `{:error, message}` if `xml` has more than `max` distinct
  element, attribute and processing instruction names. Counts generously:
  CDATA sections and comments are left out (xmerl keeps them as text),
  anything else that looks like a name counts.
  """
  def check(xml, max \\ @max) do
    case xml |> names() |> MapSet.size() do
      count when count > max ->
        {:error,
         "The XML has too many distinct element and attribute names (#{count}, at most #{max})."}

      _count ->
        :ok
    end
  end

  defp names(xml) do
    text =
      xml
      |> String.replace(~r/<!\[CDATA\[.*?\]\]>/s, "")
      |> String.replace(~r/<!--.*?-->/s, "")

    # element names (opening and closing) and processing instruction targets
    tags = Regex.scan(~r/<[\/?]?([^\s\/>!?"'=<]+)/u, text, capture: :all_but_first)
    attributes = Regex.scan(~r/\s([^\s=\/>"'<]+)\s*=\s*["']/u, text, capture: :all_but_first)

    MapSet.new(List.flatten(tags ++ attributes))
  end
end
