defmodule PanWeb.ContentSecurityPolicy do
  @moduledoc """
  Sets the Content-Security-Policy for browser pages, with a fresh nonce per
  request in `conn.assigns.csp_nonce` (used by the Live Dashboard's inline
  script).

  Sent as `content-security-policy-report-only` while
  `config :pan, :csp_enforce` isn't true: the browser then only logs
  violations to its console, and `put_secure_browser_headers`' minimal
  policy (base-uri, frame-ancestors) stays the enforced one.

  - `'unsafe-eval'`: Alpine.js evaluates its expressions with `new Function`.
  - `style-src 'unsafe-inline'`: LiveView, topbar and Alpine set `style`
    attributes; a nonce would disable `'unsafe-inline'`, so there is none.
  - `media-src`: episode audio and video come from the podcasters' hosts.
  - `img-src`: thumbnails are ours, feed HTML is sanitized without `<img>`.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64()

    conn
    |> assign(:csp_nonce, nonce)
    |> put_resp_header(header(), policy(nonce))
  end

  defp header do
    if Application.get_env(:pan, :csp_enforce, false),
      do: "content-security-policy",
      else: "content-security-policy-report-only"
  end

  defp policy(nonce) do
    Enum.join(
      [
        "default-src 'self'",
        "script-src 'self' 'nonce-#{nonce}' 'unsafe-eval'",
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' data:",
        "media-src 'self' https: http:",
        "connect-src 'self'",
        "font-src 'self' data:",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'self'"
      ],
      "; "
    )
  end
end
