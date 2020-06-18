defmodule PanWeb.Api.OpmlView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "opml"

  location(:location)
  attributes([:content_type, :filename, :inserted_at, :deleted])

  has_one(:user, serializer: PanWeb.Api.PlainUserView, include: false)

  def location(opml, conn) do
    api_opml_url(conn, :show, opml)
  end
end

defmodule PanWeb.Api.PlainOpmlView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "opml"

  location(:location)
  attributes([:content_type, :filename, :inserted_at, :deleted])

  def location(opml, conn) do
    api_opml_url(conn, :show, opml)
  end
end
