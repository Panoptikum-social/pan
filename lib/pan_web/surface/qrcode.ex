defmodule PanWeb.Surface.QRCode do
  use Surface.Component

  prop(for, :string, required: true)

  def render(assigns) do
    ~F"""
    <img src={"/qrcode/#{URI.encode_www_form(@for)}"}
         class="max-w-none"
         width="150"
         height="150" %>
    """
  end
end
