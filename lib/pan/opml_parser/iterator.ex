defmodule Pan.OpmlParser.Iterator do
  alias Pan.OpmlParser.Analyzer

  @doc "The feed URLs of the OPML nodes."
  def parse(nodes), do: Enum.flat_map(nodes, &feed_urls/1)

  defp feed_urls(%{name: name, attr: attr, value: value}), do: Analyzer.call([name, attr, value])
  defp feed_urls(_text), do: []
end
