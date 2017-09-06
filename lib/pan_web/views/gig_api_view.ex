defmodule PanWeb.GigApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "gig"

  location :gig_api_url
  attributes [:from_in_s, :until_in_s, :comment, :publishing_date, :role, :self_proclaimed,
              :persona_id, :episode_id]

  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: true
  has_one :episode, serializer: PanWeb.PlainEpisodeApiView, include: true

  def gig_api_url(gig, conn) do
    gig_api_url(conn, :show, gig)
  end
end


defmodule PanWeb.PlainGigApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "gig"

  location :gig_api_url
  attributes [:from_in_s, :until_in_s, :comment, :publishing_date, :role, :self_proclaimed,
              :persona_id, :episode_id]

  def gig_api_url(gig, conn) do
    gig_api_url(conn, :show, gig)
  end
end