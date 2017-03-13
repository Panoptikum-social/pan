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

    case download(url) do
      {:ok, feed_xml} ->

       feed_map = Pan.Parser.Helpers.remove_comments(feed_xml)
                  |> Pan.Parser.Helpers.remove_extra_angle_brackets()
                  |> Quinn.parse()

        map = %{feed: %{self_link_title: "Feed", self_link_url: url},
                        title: Enum.at(String.split(url, "/"), 2)}
              |> Iterator.parse(feed_map)
        {:ok, map}

      {:redirect, redirect_target} -> {:redirect, redirect_target}
      {:error, reason} -> {:error, reason}
    end
  end


  def download(url, option \\ nil) do
    case get(url, option) do
      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} ->
        {:error, "Timeout"}
      {:error, %HTTPoison.Error{id: nil, reason: :ehostunreach}} ->
        {:error, "Host unreachable"}
      {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}} ->
        {:error, "Domain not resolveable"}
      {:error, %HTTPoison.Error{id: nil, reason: :connect_timeout}} ->
        {:error, "Connection timeout"}

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

      {:ok, %HTTPoison.Response{status_code: 301, headers: headers}} ->
        redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} ->
        redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 307, headers: headers}} ->
        redirect(url, headers)

      {:error, %HTTPoison.Error{id: nil, reason: {:tls_alert, 'protocol version'}}} ->
        if option == "no_headers" do
          {:error, "Does not work with old tls as well!"}
        else
          download(url, "old_tls")
        end

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
          {:ok, feed_xml}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        IO.inspect get(url)
        raise "status_code unknown" <> Integer.to_string(code)
    end
  end


  def redirect(url, headers) do
    redirect_target = headers
                      |> Enum.into(%{})
                      |> Map.fetch!("Location")
    if redirect_target == url do
      {:error, "redirects to itself"}
    else
      {:redirect, redirect_target}
    end
  end


  def get(url, option \\ nil) do
    headers = case option do
      "no_headers" ->
        []
      _ ->
        ["User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:51.0) Gecko/20100101 Firefox/51.0"]
    end

    options = case option do
      "old_tls" ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]
      _ ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure],
         ssl: [{:versions, [:'tlsv1.2']}]]
    end
    HTTPoison.get(url, headers, options)
  end


# Convenience function for runtime measurement
  def measure_runtime(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
  end
end
