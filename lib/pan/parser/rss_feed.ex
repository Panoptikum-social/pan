defmodule Pan.Parser.RssFeed do
  use Pan.Web, :controller


  def demo() do
    download_and_parse("http://freakshow.fm/feed/m4a")
  end

  def download_and_parse(url) do
    feed_as_xml = File.read! "materials/source.xml"
    feed_as_map = Quinn.parse(feed_as_xml)

    changeset = %{self_link_title: "Feed",
                  self_link_url: url,
                  payment_link_title: "",
                  payment_link_url: ""}
                |> parse(feed_as_map)
                |> Pan.Podcast.changeset
# not yet implemented: persisting data from the changeset
    changeset
  end


# Actual feed parsing: Now the fun begins
  def parse(params, context \\ "tag", tags)

# We are done digging down
  def parse(params, context, []), do: params

  def parse(params, "contributor", [head | tail]) do
    contributor_params = Pan.Parser.Analyzer.call(params, "contributor", [head[:name], head[:attr], head[:value]])

    Map.merge(params, %{contributors: [contributor_params]})
    |> parse("contributor", tail)
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
