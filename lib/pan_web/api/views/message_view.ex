defmodule PanWeb.Api.MessageView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "message"

  location :location
  attributes [:content, :type, :topic, :subtopic, :event]

  has_one :creator, serializer: PanWeb.Api.PlainUserView, include: false
  has_one :persona, serializer: PanWeb.Api.PlainPersonaView, include: false

  def location(message, conn) do
    message_url(conn, :show, message)
  end
end