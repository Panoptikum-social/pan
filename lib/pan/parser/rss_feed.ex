defmodule Pan.Parser.RssFeed do
  use Pan.Web, :controller


  def demo() do
    download_and_parse("http://freakshow.fm/feed/m4a")
  end

  def download_and_parse(url) do
    feed_as_xml = File.read! "materials/source.xml"
    feed_as_map = Quinn.parse(feed_as_xml)

    params = %{self_link_title: "Feed",
               self_link_url: url}
               |> parse(feed_as_map)
    IO.inspect params
  end


# Actual feed parsing: Now the fun begins
  def parse(params, context \\ "tag", tags)

# We are done digging down
  def parse(params, _, []), do: params
  def parse(params, _, [], _), do: params


  def parse(params, "contributor", [head | tail], guid) do
    contributor_params = Pan.Parser.Analyzer.call("contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(params, %{contributors: %{String.to_atom(guid) => contributor_params}})
    |> parse("contributor", tail, guid)
  end


  def parse(params, "owner", [head | tail]) do
    owner_params = Pan.Parser.Analyzer.call(params, "owner", [head[:name], head[:attr], head[:value]])

    Map.merge(params, %{owner: owner_params})
    |> parse("owner", tail)
  end


  def parse(params, "episode", [head | tail], guid) do
    episode_params = Pan.Parser.Analyzer.call(params, "episode", [head[:name], head[:attr], head[:value]], guid)

    Pan.Parser.Helpers.deep_merge(params, %{episodes: %{String.to_atom(guid) => episode_params}})
    |> parse("episode", tail, guid)
  end


  def parse(episode_params, "episode-contributor", [head | tail], contributor_uuid) do
    contributor_params = Pan.Parser.Analyzer.call("episode-contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(episode_params, %{contributors: %{contributor_uuid => contributor_params}})
    |> parse("episode-contributor", tail, contributor_uuid)
  end


  def parse(params, context, [head | tail]) do
    Pan.Parser.Analyzer.call(params, context, [head[:name], head[:attr], head[:value]])
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
