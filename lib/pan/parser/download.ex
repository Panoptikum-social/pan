defmodule Pan.Parser.Download do
  require Logger
  alias Pan.Parser.Feed
  alias HTTPoison.{Error, Response}

  def check_for_rss(feed_xml) do
    if String.contains?(feed_xml, "<rss") do
      {:ok, feed_xml}
    else
      {:error, "not an rss feed"}
    end
  end

  def download(url, option \\ nil, feed_id \\ nil) do
    error_map = %{
      204 => "204: no content",
      304 => "304: not modified",
      400 => "400: bad request",
      401 => "401: unauthorized",
      402 => "402: payment required",
      404 => "404: feed not found",
      406 => "406: not acceptable",
      408 => "408: request timeout",
      410 => "410: gone",
      416 => "416: range not satisfiable",
      422 => "422: unprocessible entity"
    }

    case get(url, option) do
      {:ok, %Response{status_code: status_code, body: feed_xml}}
      when status_code in [200, 203, 206] ->
        check_for_rss(feed_xml)

      {:ok, %Response{status_code: status_code}}
      when status_code in [204, 304, 400, 401, 402, 404, 406, 408, 410, 416, 422] ->
        {:error, Map.get(error_map, status_code)}

      {:ok, %Response{status_code: 423}} ->
        {:error, "423: locked"}

      {:ok, %Response{status_code: 429}} ->
        {:error, "429: too many requests"}

      {:ok, %Response{status_code: 451}} ->
        {:error, "451: unavailable For legal reasons"}

      {:ok, %Response{status_code: 479}} ->
        {:error, "479: not a standard status code"}

      {:ok, %Response{status_code: 500}} ->
        {:error, "500: internal server error"}

      {:ok, %Response{status_code: 501}} ->
        {:error, "501: not implemented"}

      {:ok, %Response{status_code: 502}} ->
        {:error, "502: bad gateway"}

      {:ok, %Response{status_code: 503}} ->
        {:error, "503: service unavailable"}

      {:ok, %Response{status_code: 504}} ->
        {:error, "504: gateway time-out"}

      {:ok, %Response{status_code: 508}} ->
        {:error, "508: loop detected"}

      {:ok, %Response{status_code: 509}} ->
        {:error, "509: bandwidth limit exceeded"}

      {:ok, %Response{status_code: 520}} ->
        {:error, "520: unknown error"}

      {:ok, %Response{status_code: 521}} ->
        {:error, "521: web server is down"}

      {:ok, %Response{status_code: 523}} ->
        {:error, "523: origin is unreachable"}

      {:ok, %Response{status_code: 526}} ->
        {:error, "526: invalid SSL certificate"}

      {:ok, %Response{status_code: 530}} ->
        {:error, "530: origin DNS error with cloudflare"}

      {:ok, %Response{status_code: 301, headers: headers}} ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: 302, headers: headers}} ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: 303, headers: headers}} ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: 308, headers: headers}} ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: 307}} ->
        {:error, "307: temporary redirect"}

      {:ok, %Response{status_code: 403}} ->
        if option == "no_headers" do
          {:error, "403: forbidden"}
        else
          download(url, "no_headers")
        end

      {:ok, %Response{status_code: code}} ->
        Logger.error("status_code unknown #{inspect(code)}")

      {:error, %Error{id: nil, reason: :timeout}} ->
        {:error, "Timeout"}

      {:error, %Error{id: nil, reason: :ehostunreach}} ->
        {:error, "Host unreachable"}

      {:error, %Error{id: nil, reason: :nxdomain}} ->
        {:error, "Domain not resolveable"}

      {:error, %Error{id: nil, reason: :connect_timeout}} ->
        {:error, "Connection timeout"}

      {:error, %Error{id: nil, reason: :econnrefused}} ->
        {:error, "Connection refused"}

      {:error, %Error{id: nil, reason: :closed}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:closed, _feed_xml}}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:tls_alert, 'handshake failure'}}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:tls_alert, 'protocol version'}}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:tls_alert, 'unrecognised name'}}} ->
        try_without_tls_set(url, option)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def try_without_tls_set(url, option) do
    case option do
      "unset_tls_version" -> {:error, "Does not work without specifying tls version as well!"}
      _ -> download(url, "unset_tls_version")
    end
  end

  def redirect(url, headers, feed_id) do
    header_map = Enum.into(headers, %{})

    redirect_target =
      if Map.has_key?(header_map, "Location") do
        Map.fetch!(header_map, "Location")
      else
        Map.fetch!(header_map, "location")
      end

    Feed.check_for_redirect_loop(url, redirect_target, feed_id)
  end

  def get(url, option) do
    headers =
      if option == "no_headers" do
        []
      else
        ["User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.io/)"]
      end

    ssl_versions =
      if option == "unset_tls_version" do
        [:"tlsv1.2"]
      else
        [:"tlsv1.2", :"tlsv1.1", :tlsv1]
      end

    HTTPoison.get(url, headers,
      recv_timeout: 10_000,
      timeout: 10_000,
      hackney: [:insecure],
      ssl: [{:versions, ssl_versions}]
    )
  end
end
