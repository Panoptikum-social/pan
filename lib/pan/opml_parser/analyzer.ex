defmodule Pan.OpmlParser.Analyzer do
  alias Pan.OpmlParser.Iterator
  require Logger

  # A node's feed URLs: an rss outline's xmlUrl if it's an http(s) URL
  # (anything else, or a missing one, is skipped), the URLs nested in
  # wrappers and folder outlines.

  # wrappers to dive into
  def call([:opml, _, value]), do: Iterator.parse(value)
  def call([:body, _, value]), do: Iterator.parse(value)

  def call([:outline, attr, value]) do
    case attr[:type] do
      "rss" -> feed_url(attr[:xmlUrl])
      "atom" -> []
      nil -> Iterator.parse(value)
    end
  end

  # tags to ignore
  def call([tag_atom, _, _])
      when tag_atom in [
             :head
           ],
      do: []

  def call([tag, attr, value]) do
    Logger.error("Tag unknown:")
    Logger.error(~s(Tag: :"#{tag}"))
    Logger.error("Attr: #{inspect(attr)}")
    Logger.error("Value: #{inspect(value)}")
    raise "Tag unknown"
  end

  defp feed_url(url) when is_binary(url) do
    url = String.trim(url)

    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and is_binary(host) ->
        [url]

      _ ->
        []
    end
  end

  defp feed_url(_url), do: []
end
