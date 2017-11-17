defmodule Pan.Parser.Download do
  require Logger

  def check_for_rss(feed_xml) do
    if String.contains?(feed_xml, "<rss") do
      {:ok, feed_xml}
    else
      {:error, "This is not an rss feed!"}
    end
  end


  def download(url, option \\ nil) do
    case get(url, option) do
      {:ok, %HTTPoison.Response{status_code: 200, body: feed_xml}} -> check_for_rss(feed_xml)
      {:ok, %HTTPoison.Response{status_code: 203, body: feed_xml}} -> check_for_rss(feed_xml)
      {:ok, %HTTPoison.Response{status_code: 206, body: feed_xml}} -> check_for_rss(feed_xml)

      {:ok, %HTTPoison.Response{status_code: 401}} -> {:error, "401: unauthorized"}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, "404: feed not found"}
      {:ok, %HTTPoison.Response{status_code: 406}} -> {:error, "406: not acceptable"}
      {:ok, %HTTPoison.Response{status_code: 410}} -> {:error, "410: Gone"}
      {:ok, %HTTPoison.Response{status_code: 422}} -> {:error, "422: Unprocessible entity"}
      {:ok, %HTTPoison.Response{status_code: 429}} -> {:error, "429: To many requests"}
      {:ok, %HTTPoison.Response{status_code: 479}} -> {:error, "479: Not a standard status code"}

      {:ok, %HTTPoison.Response{status_code: 500}} -> {:error, "500: internal server error"}
      {:ok, %HTTPoison.Response{status_code: 502}} -> {:error, "502: bad gateway"}
      {:ok, %HTTPoison.Response{status_code: 503}} -> {:error, "503: service unavailable"}
      {:ok, %HTTPoison.Response{status_code: 504}} -> {:error, "504: gateway time-out"}
      {:ok, %HTTPoison.Response{status_code: 508}} -> {:error, "508: loop detected"}
      {:ok, %HTTPoison.Response{status_code: 509}} -> {:error, "509: Bandwidth Limit Exceeded"}
      {:ok, %HTTPoison.Response{status_code: 520}} -> {:error, "520: Unknown Error"}
      {:ok, %HTTPoison.Response{status_code: 521}} -> {:error, "521: Web server is down"}

      {:ok, %HTTPoison.Response{status_code: 301, headers: headers}} -> redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} -> redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 303, headers: headers}} -> redirect(url, headers)
      {:ok, %HTTPoison.Response{status_code: 307, headers: headers}} -> redirect(url, headers)

      {:ok, %HTTPoison.Response{status_code: 403}} ->
        if option == "no_headers" do
          {:error, "403: forbidden"}
        else
         download(url, "no_headers")
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error "status_code unknown #{inspect code}"

      {:error, %HTTPoison.Error{id: nil, reason: :timeout}} -> {:error, "Timeout"}
      {:error, %HTTPoison.Error{id: nil, reason: :ehostunreach}} -> {:error, "Host unreachable"}
      {:error, %HTTPoison.Error{id: nil, reason: :nxdomain}} -> {:error, "Domain not resolveable"}
      {:error, %HTTPoison.Error{id: nil, reason: :connect_timeout}} -> {:error, "Connection timeout"}
      {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} -> {:error, "Connection refused"}

      {:error, %HTTPoison.Error{id: nil, reason: :closed}} ->
        try_without_tls_set(url, option)
      {:error, %HTTPoison.Error{id: nil, reason: {:tls_alert, 'handshake failure'}}} ->
        try_without_tls_set(url, option)
      {:error, %HTTPoison.Error{id: nil, reason: {:tls_alert, 'protocol version'}}} ->
        try_without_tls_set(url, option)

      {:error, reason} -> {:error, reason}
    end
  end


  def try_without_tls_set(url, option) do
    case option do
      "unset_tls_version" -> {:error, "Does not work without specifying tls version as well!"}
                        _ -> download(url, "unset_tls_version")
    end
  end


  def redirect(url, headers) do
    header_map = Enum.into(headers, %{})
    redirect_target = if Map.has_key?(header_map, "Location") do
      Map.fetch!(header_map, "Location")
    else
      Map.fetch!(header_map, "location")
    end

    redirect_target =
      case String.starts_with?(redirect_target, "http") do
        true -> redirect_target
        false ->
          domain = String.split(url, "/", parts: 3, trim: true)
                   |> Enum.drop(-1)
                   |> Enum.join("//")
          domain <> redirect_target
      end

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
      "unset_tls_version" ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure],
         ssl: [{:versions, [:'tlsv1.2']}]]
      _ ->
        [recv_timeout: 15_000, timeout: 15_000, hackney: [:insecure]]
    end
    HTTPoison.get(url, headers, options)
  end
end
