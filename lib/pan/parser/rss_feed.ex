defmodule Pan.Parser.RssFeed do
  alias Pan.Parser.Iterator
  alias Pan.Parser.Persistor

  def demo do
    initial_import("https://rechtsbelehrung.com/feed/podcast/")
  end


  def initial_import(url, pagecount \\ 1) do
    {:ok, map} = import_to_map(url)
    podcast_id = Persistor.initial_import(map)

    next_page_url = map[:feed][:next_page_url]
    pagecount = pagecount + 1
    if next_page_url != nil and pagecount < 26 do
      initial_import(next_page_url, pagecount)
    end

    podcast_id
  end


  def import_to_map(url) do
    url = String.strip(url)
    IO.puts "\n\e[96m === Download from: " <> url <> " ===\e[0m"

    download(url)
  end


  def download(url, option \\ nil) do
    case get(url, option) do
      {:ok, %HTTPoison.Response{status_code: 500}} ->
        {:error, "500: internal server error"}
      {:ok, %HTTPoison.Response{status_code: 502}} ->
        {:error, "502: bad gateway"}
      {:ok, %HTTPoison.Response{status_code: 503}} ->
        {:error, "503: service unavailable"}
      {:ok, %HTTPoison.Response{status_code: 504}} ->
        {:error, "504: gateway time-out"}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "404: feed not found"}

      {:ok, %HTTPoison.Response{status_code: 403}} ->
        if option == "no_headers" do
          {:error, "403: forbidden"}
        else
         download(url, "no_headers")
        end

      {:ok, %HTTPoison.Response{status_code: 200, body: feed_xml}} ->
        unless String.contains?(feed_xml, "<rss") do
          {:error, "This is not an rss feed!"}
        else
          feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
                     |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                     |> Quinn.parse()
          map = %{feed: %{self_link_title: "Feed", self_link_url: url},
                          title: Enum.at(String.split(url, "/"), 2)}
                |> Iterator.parse(feed_map)
          {:ok, map}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.inspect get(url)
        IO.puts "=========================="
        raise "status_code unknown" <> code
    end
  end

  def get(url, option \\ nil) do
    case option do
      "no_headers" ->
        HTTPoison.get(url, [],
                           [connect_timeout: 20_000, recv_timeout: 20_000, follow_redirects: true,
                            max_redirect: 5, timeout: 20_000, hackney: [:insecure],
                            ssl: [{:versions, [:'tlsv1.2']}]])
      nil ->
        HTTPoison.get(url, [{"User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " <>
                                           "(KHTML, like Gecko) " <>
                                           "Chrome/49.0.2623.75 Safari/537.36"}],
                           [follow_redirect: true, max_redirect: 5, connect_timeout: 20_000,
                            recv_timeout: 20_000, timeout: 20_000, hackney: [:insecure],
                            ssl: [{:versions, [:'tlsv1.2']}]])
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