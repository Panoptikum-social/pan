defmodule Pan.Parser.RssFeed do
  use Pan.Web, :controller


  def demo() do
    download_and_parse("http://freakshow.fm/feed/m4a")
  end

  def download_and_parse(url) do
    feed_as_xml = File.read! "materials/source.xml"
    feed_as_map = Quinn.parse(feed_as_xml)

    %{self_link_title: "Feed", self_link_url: url}
    |> parse(feed_as_map)
  end


# Actual feed parsing: Now the fun begins
  def parse(map, context \\ "tag", tags)

# We are done digging down
  def parse(map, _, []), do: map
  def parse(map, _, [], _), do: map


  def parse(map, "contributor", [head | tail], guid) do
    contributor_map = Pan.Parser.Analyzer.call("contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{contributors: %{String.to_atom(guid) => contributor_map}})
    |> parse("contributor", tail, guid)
  end


  def parse(map, "owner", [head | tail]) do
    owner_map = Pan.Parser.Analyzer.call(map, "owner", [head[:name], head[:attr], head[:value]])

    Map.merge(map, %{owner: owner_map})
    |> parse("owner", tail)
  end


  def parse(map, "episode", [head | tail], guid) do
    episode_map = Pan.Parser.Analyzer.call(map, "episode", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{episodes: %{String.to_atom(guid) => episode_map}})
    |> parse("episode", tail, guid)
  end


  def parse(map, "chapter", [head | tail]) do
    chapter_map = Pan.Parser.Analyzer.call("chapter", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{chapters: chapter_map})
    |> parse("chapter", tail)
  end


  def parse(map, "episode-contributor", [head | tail], contributor_uuid) do
    contributor_map = Pan.Parser.Analyzer.call("episode-contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{contributors: %{contributor_uuid => contributor_map}})
    |> parse("episode-contributor", tail, contributor_uuid)
  end


  def parse(map, context, [head | tail]) do
    podcast_map = Pan.Parser.Analyzer.call(map, context, [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, podcast_map)
    |> parse(context, tail)
  end


# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end

#    %HTTPoison.Response{body: feed_as_xml} = HTTPoison.get!(url, [], [follow_redirect: true,
#                                                                      connect_timeout: 20000,
#                                                                      recv_timeout: 20000,
#                                                                      timeout: 20000])
