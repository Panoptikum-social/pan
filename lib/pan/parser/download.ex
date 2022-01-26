defmodule Pan.Parser.Download do
  require Logger
  alias Pan.Parser.Feed
  alias HTTPoison.{Error, Response}

  defp check_for_rss(feed_xml) do
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
      307 => "307: temporary redirect",
      400 => "400: bad request",
      401 => "401: unauthorized",
      402 => "402: payment required",
      404 => "404: feed not found",
      406 => "406: not acceptable",
      408 => "408: request timeout",
      410 => "410: gone",
      416 => "416: range not satisfiable",
      422 => "422: unprocessible entity",
      423 => "423: locked",
      429 => "429: too many requests",
      451 => "451: unavailable For legal reasons",
      479 => "479: not a standard status code",
      500 => "500: internal server error",
      501 => "501: not implemented",
      502 => "502: bad gateway",
      503 => "503: service unavailable",
      504 => "504: gateway time-out",
      508 => "508: loop detected",
      509 => "509: bandwidth limit exceeded",
      520 => "520: unknown error",
      521 => "521: web server is down",
      523 => "523: origin is unreachable",
      526 => "526: invalid SSL certificate",
      530 => "530: origin DNS error with cloudflare"
    }

    error_translations = %{
      timeout: "Timeout",
      ehostunreach: "Host unreachable",
      nxdomain: "Domain not resolveable",
      connect_timeout: "Connection timeout",
      econnrefused: "Connection refused"
    }

    case get(url, option) do
      {:ok, %Response{status_code: status_code, body: feed_xml}}
      when status_code in [200, 203, 206] ->
        check_for_rss(feed_xml)

      {:ok, %Response{status_code: status_code}}
      when status_code in [204, 304, 307, 400, 401, 402, 404, 406, 408, 410, 416, 422, 423] ->
        {:error, Map.get(error_map, status_code)}

      {:ok, %Response{status_code: status_code}}
      when status_code in [429, 451, 479, 500, 501, 502, 503, 504, 508, 509, 520, 521, 523] ->
        {:error, Map.get(error_map, status_code)}

      {:ok, %Response{status_code: status_code}}
      when status_code in [526, 530] ->
        {:error, Map.get(error_map, status_code)}

      {:ok, %Response{status_code: status_code, headers: headers}}
      when status_code in [301, 302, 303, 308] ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: 403}} ->
        if option == "no_headers" do
          {:error, "403: forbidden"}
        else
          download(url, "no_headers")
        end

      {:ok, %Response{status_code: code}} ->
        Logger.error("status_code unknown #{inspect(code)}")

      {:error, %Error{id: nil, reason: reason}}
      when reason in [:timeout, :ehostunreach, :nxdomain, :connect_timeout, :econnrefused] ->
        {:error, Map.get(error_translations, reason)}

      {:error, %Error{id: nil, reason: :closed}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:closed, _feed_xml}}} ->
        try_without_tls_set(url, option)

      {:error, %Error{id: nil, reason: {:tls_alert, alert_message}}}
      when alert_message in ["handshake failure", "protocol version", "unrecognised name"] ->
        try_without_tls_set(url, option)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp try_without_tls_set(url, option) do
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
