defmodule PanWeb.OpmlApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "opml"

  location :opml_feed_api_url
  attributes [:content_type, :filename, :inserted_at, :deleted]

  has_one :user, serializer: PanWeb.PlainUserApiView, include: false

  def opml_feed_api_url(opml, conn) do
    opml_api_url(conn, :show, opml)
  end
end
