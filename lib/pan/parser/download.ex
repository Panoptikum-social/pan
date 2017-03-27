defmodule Pan.Parser.Download do
  require Logger

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
      {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} ->
        {:error, "Connection refused"}


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
      {:ok, %HTTPoison.Response{status_code: 429}} ->
        {:error, "429: To many requests"}


      {:error, %HTTPoison.Error{id: nil, reason: :closed}} ->
        if option == "set_tls_version" do
          {:error, "Does not work with old tls as well!"}
        else
          download(url, "set_tls_version")
        end

      {:error, %HTTPoison.Error{id: nil, reason: {:tls_alert, 'protocol version'}}} ->
        if option == "set_tls_version" do
          {:error, "Does not work with old tls as well!"}
        else
          download(url, "set_tls_version")
        end

      {:ok, %HTTPoison.Response{status_code: 301, headers: headers}} ->
        redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} ->
        redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 307, headers: headers}} ->
        redirect(url, headers)

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
        Logger.error "status_code unknown " <> Integer.to_string(code)
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
      "set_tls_version" ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]
      _ ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure],
         ssl: [{:versions, [:'tlsv1.2']}]]
    end
    HTTPoison.get(url, headers, options)
  end
end