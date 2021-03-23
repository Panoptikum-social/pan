defmodule PanWeb.QRCodeFrontendController do
  use PanWeb, :controller

  def generate(conn, %{"code" => code}) do
    svg =
      code
      |> EQRCode.encode()
      |> EQRCode.svg()

    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, svg)
  end
end
