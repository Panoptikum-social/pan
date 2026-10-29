defmodule PanWeb.QRCodeFrontendController do
  use PanWeb, :controller

  # Mocha keeps the normal polarity (dark modules on light; inverted codes
  # are optional in the standard), only in Mocha base on Mocha text, 11:1
  # (backlog.md #456). Latte stays black on white.
  def generate(conn, %{"code" => code} = params) do
    colors =
      case params["theme"] do
        "mocha" -> [color: "#1e1e2e", background_color: "#cdd6f4"]
        _ -> []
      end

    svg =
      code
      |> EQRCode.encode()
      |> EQRCode.svg([width: 150] ++ colors)

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, svg)
  end
end
