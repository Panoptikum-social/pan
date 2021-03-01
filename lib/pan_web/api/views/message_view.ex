defmodule PanWeb.Api.MessageView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  location(:location)
  attributes([:content, :msg_type, :topic, :subtopic, :event])

  def type(_, _), do: "message"

  has_one(:creator, serializer: PanWeb.Api.PlainUserView, include: false)
  has_one(:persona, serializer: PanWeb.Api.PlainPersonaView, include: false)

  def location(message, conn) do
    api_message_url(conn, :show, message)
  end

  def msg_type(message) do
    message.type
  end
end

defmodule PanWeb.Api.PlainMessageView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  location(:location)
  attributes([:content, :msg_type, :topic, :subtopic, :event])

  def type(_, _), do: "message"

  def location(message, conn) do
    api_message_url(conn, :show, message)
  end

  def msg_type(message) do
    message.type
  end
end
