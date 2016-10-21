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
    changeset
  end

  def parse(params, context \\ "tag", tags)
  def parse(params, "image", []), do: params

  def parse(params, context, [head | tail]) do
    params = Pan.Parser.Analyzer.call(params, context, [head[:name], head[:attr], head[:value]])
    parse(params, context, tail)
    params
  end


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
