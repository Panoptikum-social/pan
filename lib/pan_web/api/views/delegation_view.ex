defmodule PanWeb.Api.DelegationView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "delegation"

  location(:location)

  attributes([:created, :deleted])

  has_one(:persona, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_one(:delegate, serializer: PanWeb.Api.PlainPersonaView, include: false)

  def location(delegation, conn) do
    api_delegation_url(conn, :show, delegation)
  end
end
