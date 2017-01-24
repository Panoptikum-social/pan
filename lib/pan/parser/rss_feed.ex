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

    download_and_error_handling(url)
  end


  def download_and_error_handling(url, option \\ nil) do
    case download(url, option) do
      %HTTPotion.ErrorResponse{message: "econnrefused"} ->
        {:error, "connection refused"}

      %HTTPotion.ErrorResponse{message: "req_timedout"} ->
        {:error, "request timed out"}

      %HTTPotion.Response{status_code: 500} ->
        {:error, "500: internal server error"}

      %HTTPotion.Response{status_code: 503} ->
        {:error, "503: service unavailable"}

      %HTTPotion.Response{status_code: 504} ->
        {:error, "504: gateway time-out"}

      %HTTPotion.Response{status_code: 404} ->
        {:error, "404: feed not found"}

      %HTTPotion.Response{status_code: 403} ->
        if option == "no_headers" do
          {:error, "403: forbidden"}
        else
         download_and_error_handling(url, "no_headers")
        end

      %HTTPotion.Response{status_code: 200, body: feed_xml} ->
        # IO.inspect download(url)
        # IO.puts "=========================="

        if String.starts_with?(feed_xml, "<html") or
           String.starts_with?(feed_xml, "<!DOCTYPE html>") or
           String.starts_with?(feed_xml, "<?php") do
          {:error, "This is an HTML/PHP file, not a feed!"}
        else
          feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
                     |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                     |> Quinn.parse()
          map = %{feed: %{self_link_title: "Feed", self_link_url: url},
                          title: Enum.at(String.split(url, "/"), 2)}
                |> Iterator.parse(feed_map)
          {:ok, map}
        end

      %HTTPotion.Response{status_code: code} ->
        IO.inspect download(url)
        IO.puts "=========================="
        raise "status_code unknown" <> code
    end
  end


  def download(url, option \\ nil) do
    case option do
      "no_headers" ->
        HTTPotion.get url, [timeout: 20000, follow_redirects: true]
      nil ->
        HTTPotion.get url,
          [timeout: 20000, follow_redirects: true,
          headers: ["User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36"]]
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