defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor

  def demo do
    download_and_parse("https://rechtsbelehrung.com/feed/podcast/")
  end

  def download_and_parse(url, pagecount \\ 1) do
    url = String.strip(url)
    %HTTPotion.Response{body: feed_xml} = download(url)

    IO.puts "\n\e[96m === URL: " <> url <> " ===\e[0m"

    feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
               |> Pan.Parser.Helpers.remove_extra_angle_brackets()
               |> Quinn.parse()
    map = %{feed: %{self_link_title: "Feed", self_link_url: url},
            title: Enum.at(String.split(url, "/"), 2)}
          |> Iterator.parse(feed_map)

    podcast_id = Persistor.call(map)

    next_page_url = map[:feed][:next_page_url]
    pagecount = pagecount + 1
    if next_page_url and pagecount < 100 do
      download_and_parse(next_page_url, pagecount)
    end

    podcast_id
  end


  def download(url) do
    HTTPotion.get url,
      [timeout: 20000, follow_redirects: true,
       headers: ["User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"]]
  end

# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end