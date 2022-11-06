defmodule Pan.Parser.Download do
  require Logger
  alias Pan.Parser.Feed
  alias HTTPoison.{Error, Response}

  def download(url, feed_id \\ nil) do
    error_map = %{
      204 => "204: no content",
      304 => "304: not modified",
      307 => "307: temporary redirect",
      400 => "400: bad request",
      401 => "401: unauthorized",
      402 => "402: payment required",
      403 => "403: forbidden",
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
      econnrefused: "Connection refused",
      closed: "Connection closed"
    }

    case get(url) do
      {:ok, %Response{status_code: status_code, body: feed_xml}}
      when status_code in [200, 203, 206] ->
        check_for_rss(feed_xml)

      {:ok, %Response{status_code: status_code}}
      when status_code in [
             204,
             304,
             307,
             400,
             401,
             402,
             403,
             404,
             406,
             408,
             410,
             416,
             422,
             423,
             429,
             451,
             479,
             500,
             501,
             502,
             503,
             504,
             508,
             509,
             520,
             521,
             523,
             526,
             530
           ] ->
        {:error, Map.get(error_map, status_code)}

      {:ok, %Response{status_code: status_code, headers: headers}}
      when status_code in [301, 302, 303, 308] ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: code}} ->
        Logger.error("status_code unknown #{inspect(code)}")

      {:error, %Error{id: nil, reason: reason}}
      when reason in [
             :timeout,
             :ehostunreach,
             :nxdomain,
             :connect_timeout,
             :econnrefused,
             :closed
           ] ->
        {:error, Map.get(error_translations, reason)}

      {:error, %Error{id: nil, reason: {:closed, _feed_xml}}} ->
        {:error, Map.get(error_translations, :closed)}

      {:error, %Error{id: nil, reason: {:tls_alert, alert_message}}}
      when alert_message in ["handshake failure", "protocol version", "unrecognised name"] ->
        {:error, alert_message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_for_rss(feed_xml) do
    if String.contains?(feed_xml, "<rss") do
      {:ok, feed_xml}
    else
      {:error, "not an rss feed"}
    end
  end

  defp redirect(url, headers, feed_id) do
    header_map = Enum.into(headers, %{})

    redirect_target = Map.get(header_map, "Location") || Map.get(header_map, "location")
    Feed.check_for_redirect_loop(url, redirect_target, feed_id)
  end

  def get(url) do
    HTTPoison.get(
      url,
      ["User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.social/)"],
      recv_timeout: 10_000,
      timeout: 10_000
    )
  end
end
