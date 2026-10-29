defmodule PanWeb.Component.QRCode do
  use PanWeb, :html

  # Both variants are rendered, CSS in app.css shows the one of the active
  # theme: an <img> SVG doesn't see data-theme on our <html>.
  attr :for, :string, required: true

  def render(assigns) do
    ~H"""
    <img
      src={"/qrcode/#{URI.encode_www_form(@for)}"}
      alt="QR code"
      class="qr-latte max-w-none"
      width="150"
      height="150"
    />
    <img
      src={"/qrcode/#{URI.encode_www_form(@for)}?theme=mocha"}
      alt="QR code"
      class="qr-mocha max-w-none"
      width="150"
      height="150"
    />
    """
  end
end
