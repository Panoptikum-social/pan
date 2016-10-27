defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor

  def demo do
    download_and_parse("http://feeds.metaebene.me/freakshow/m4a")
  end

  def download_and_parse(url) do
    %HTTPoison.Response{body: feed_xml} = HTTPoison.get!(url, [], [follow_redirect: true,
                                                                      connect_timeout: 20000,
                                                                      recv_timeout: 20000,
                                                                      timeout: 20000])

    feed_map = Quinn.parse(feed_xml)

    map = %{self_link_title: "Feed", self_link_url: url}
          |> Iterator.parse(feed_map)

    Persistor.call(map)

    next_page_url = map[:feed][:next_page_url]
    if next_page_url do
      download_and_parse(next_page_url)
    end
  end

# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end