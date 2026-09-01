defmodule Pan.Parser.Download do
  require Logger
  alias HTTPoison.{Error, Response}
  alias Pan.Parser.{Feed, SsrfGuard}

  @error_map %{
    202 => "202: accepted",
    204 => "204: no content",
    304 => "304: not modified",
    307 => "307: temporary redirect",
    400 => "400: bad request",
    401 => "401: unauthorized",
    402 => "402: payment required",
    403 => "403: forbidden",
    404 => "404: feed not found",
    405 => "405: method not allowed",
    406 => "406: not acceptable",
    408 => "408: request timeout",
    409 => "409: conflict",
    410 => "410: gone",
    416 => "416: range not satisfiable",
    421 => "421: misdirected request",
    422 => "422: unprocessible entity",
    423 => "423: locked",
    428 => "428: precondition required",
    429 => "429: too many requests",
    437 => "437: not a standard status code",
    440 => "440: login timeout",
    451 => "451: unavailable For legal reasons",
    479 => "479: not a standard status code",
    500 => "500: internal server error",
    501 => "501: not implemented",
    502 => "502: bad gateway",
    503 => "503: service unavailable",
    504 => "504: gateway time-out",
    508 => "508: loop detected",
    506 => "506: variant also negotiates",
    509 => "509: bandwidth limit exceeded",
    520 => "520: unknown error",
    521 => "521: web server is down",
    523 => "523: origin is unreachable",
    525 => "525: SSL handshake failed",
    526 => "526: invalid SSL certificate",
    530 => "530: origin DNS error with cloudflare",
    534 => "534: anycast: origin unreachable",
    999 => "999: not a standard status code"
  }

  @error_translations %{
    timeout: "Timeout",
    ehostunreach: "Host unreachable",
    nxdomain: "Domain not resolveable",
    connect_timeout: "Connection timeout",
    econnrefused: "Connection refused",
    closed: "Connection closed"
  }

  def download(url, feed_id \\ nil) do
    case get(url) do
      {:ok, %Response{status_code: status_code, body: feed_xml}}
      when status_code in [200, 203, 206] ->
        check_for_rss(feed_xml)

      {:ok, %Response{status_code: status_code}}
      when status_code in [
             202,
             204,
             304,
             307,
             400,
             401,
             402,
             403,
             404,
             405,
             406,
             408,
             409,
             410,
             416,
             421,
             422,
             423,
             428,
             429,
             437,
             440,
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
             525,
             526,
             530,
             534,
             999
           ] ->
        {:error, Map.get(@error_map, status_code)}

      {:ok, %Response{status_code: status_code, headers: headers}}
      when status_code in [301, 302, 303, 308] ->
        redirect(url, headers, feed_id)

      {:ok, %Response{status_code: code}} ->
        Logger.error("status_code unknown #{inspect(code)}")

      {:error, %Error{} = error} ->
        translate_error(error)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp translate_error(%Error{id: nil, reason: reason})
       when reason in [
              :timeout,
              :ehostunreach,
              :nxdomain,
              :connect_timeout,
              :econnrefused,
              :closed
            ] do
    {:error, Map.get(@error_translations, reason)}
  end

  defp translate_error(%Error{id: nil, reason: {:closed, _feed_xml}}) do
    {:error, Map.get(@error_translations, :closed)}
  end

  defp translate_error(%Error{id: nil, reason: {:tls_alert, {alert_type, _description}}})
       when alert_type in [
              :handshake_failure,
              :protocol_version,
              :unrecognised_name,
              :certificate_expired
            ] do
    {:error, "TLS error: #{alert_type}"}
  end

  # Catch-all for any HTTPoison.Error shape not specifically handled above —
  # %HTTPoison.Error{} doesn't implement String.Chars, so passing the raw
  # struct through crashes the first caller that interpolates it into a
  # log/notification message (seen in Pan.Job.RefreshPodcastMetadata for an
  # untranslated :certificate_expired TLS alert, 2026-09-01).
  defp translate_error(%Error{reason: reason}) do
    {:error, "HTTP error: #{inspect(reason)}"}
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

  # extra_options is merged in as-is (e.g. `follow_redirect: true` for a
  # caller that doesn't need to inspect the redirect chain itself) —
  # deliberately not the default here, since download/2 relies on redirects
  # *not* being auto-followed to detect and persist 301/etc. targets itself.
  def get(url, extra_options \\ []) do
    with :ok <- SsrfGuard.check(url) do
      headers = [
        "User-Agent": "Mozilla/5.0 (compatible; Panoptikum; +https://panoptikum.social/)"
      ]

      options = [recv_timeout: 10_000, timeout: 10_000] ++ extra_options

      case HTTPoison.get(url, headers, options) do
        {:error, %Error{id: nil, reason: {:tls_alert, {:handshake_failure, _description}}}} ->
          # Some servers' TLS 1.3 handling is incompatible with Erlang's client hello,
          # while TLS 1.2 negotiates fine (e.g. www.br50.org).
          HTTPoison.get(url, headers, options ++ [ssl: [versions: [:"tlsv1.2"]]])

        response ->
          response
      end
    end
  rescue
    # A genuinely garbled response (e.g. a status line full of stray NUL
    # bytes) makes hackney's parser raise instead of returning an
    # HTTPoison.Error tuple — that shouldn't take down the whole import job.
    e ->
      Logger.warning("HTTP client crashed for #{url}: #{Exception.message(e)}")
      {:error, %Error{reason: Exception.message(e)}}
  end
end
