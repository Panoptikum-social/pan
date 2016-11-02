defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor

  def demo do
    download_and_parse("https://rechtsbelehrung.com/feed/podcast/")
  end

  def download_and_parse(url) do
    url = String.strip(url)
    %HTTPoison.Response{body: feed_xml} = download(url)

    IO.puts "\n\e[96m === URL: " <> url <> " ===\e[0m"

    feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
               |> Quinn.parse()

    map = %{feed: %{self_link_title: "Feed", self_link_url: url},
            title: Enum.at(String.split("http://www.derblindefleck.de/feed/", "/"), 2)}
          |> Iterator.parse(feed_map)

    podcast_id = Persistor.call(map)

    next_page_url = map[:feed][:next_page_url]
    if next_page_url do
      download_and_parse(next_page_url)
    end

    podcast_id
  end


  def download(url) do
    HTTPoison.get!(url,
               [{"User-Agent",
                 "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"},
                {"content-type", "text/html,application/xhtml+xml,application/xml;charset=UTF-8"}],
               [follow_redirect: true, connect_timeout: 20000, recv_timeout: 20000, timeout: 20000])
  end

# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end