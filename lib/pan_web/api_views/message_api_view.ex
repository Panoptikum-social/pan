defmodule PanWeb.MessageApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "message"

  location :message_api_url
  attributes [:content, :type, :topic, :subtopic, :event]

  has_one :creator, serializer: PanWeb.PlainUserApiView, include: false
  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: false

  def message_api_url(message, conn) do
    message_api_url(conn, :show, message)
  end
end