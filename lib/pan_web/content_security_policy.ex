defmodule PanWeb.ContentSecurityPolicy do
  @moduledoc """
  Sets the Content-Security-Policy for browser pages, with a fresh nonce per
  request in `conn.assigns.csp_nonce` (used by the Live Dashboard's inline
  script).

  Sent as `content-security-policy-report-only` while
  `config :pan, :csp_enforce` isn't true: the browser then only logs
  violations to its console, and `put_secure_browser_headers`' minimal
  policy (base-uri, frame-ancestors) stays the enforced one.

  - `'unsafe-eval'`: the Podlove subscribe button compiles its modal's
    templates with `new Function` when it's clicked (prod, 2026-10-19).
    Alpine runs on its CSP build anyway (assets/js/app.js), so injected
    `x-*` attributes still can't run arbitrary code.
  - script hashes: the Podlove Web Player writes inline scripts into iframes
    without a src, which inherit this policy (see @podlove_script_hashes).
  - `style-src 'unsafe-inline'`: LiveView, topbar and Alpine set `style`
    attributes; a nonce would disable `'unsafe-inline'`, so there is none.
  - `media-src`: episode audio and video come from the podcasters' hosts.
  - `img-src`: thumbnails are ours, feed HTML is sanitized without `<img>`.
  """
  import Plug.Conn

  # Podlove Web Player 5.7.4 (priv/static/web-player/), read from its iframes
  # in the browser: the iFrameResizer setup and the app load handler. A new
  # player version needs new hashes, and a check of the scripts built in
  # podlove_scripts/0.
  @podlove_version "5.7.4"
  @podlove_script_hashes [
    "sha256-6Y0v1n/Y21n6mdU+5WDKH8kQ1ww6CLuplpFeCWJUrlY=",
    "sha256-/CocAxQERUuy7+nrYskHO8hLR8mtDfSuQqZ3lyoxCS4="
  ]

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

  @doc false
  # public for the test, which pins the hashes browsers reported for prod
  def podlove_script_hashes(url \\ PanWeb.Endpoint.url()) do
    Enum.map(
      podlove_scripts(url),
      &("'sha256-" <> Base.encode64(:crypto.hash(:sha256, &1)) <> "'")
    ) ++
      Enum.map(@podlove_script_hashes, &"'#{&1}'")
  end

  # the player's scripts that contain the site's URL, character for character:
  # the resource base URL of the player and its subscribe button, and the
  # polyfill loader (in both)
  defp podlove_scripts(url) do
    [
      "window.resourceBaseUrl = '#{url}/web-player/#{@podlove_version}/player/';",
      "window.resourceBaseUrl = '#{url}/web-player/#{@podlove_version}/button/';",
      """
      const modernBrowser = (
            'fetch' in window &&
            'assign' in Object
          );

          if ( !modernBrowser ) {
            const scriptElement = document.createElement('script');

            scriptElement.async = false;
            scriptElement.src = '#{url}/web-player/polyfills.js';
            document.head.appendChild(scriptElement);
          }\
      """
    ]
  end

  defp policy(nonce) do
    Enum.join(
      [
        "default-src 'self'",
        Enum.join(
          ["script-src 'self' 'nonce-#{nonce}' 'unsafe-eval'" | podlove_script_hashes()],
          " "
        ),
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
