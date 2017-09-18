defmodule PanWeb.DelegationApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "delegation"

  location :delegation_api_url

  attributes [:created, :deleted]

  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: false
  has_one :delegate, serializer: PanWeb.PlainPersonaApiView, include: false

  def delegation_api_url(delegation, conn) do
    delegation_api_url(conn, :show, delegation)
  end
end
