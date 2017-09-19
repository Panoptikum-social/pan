defmodule PanWeb.Api.GigView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "gig"

  location :location
  attributes [:from_in_s, :until_in_s, :comment, :publishing_date, :role, :self_proclaimed,
              :persona_id, :episode_id, :created, :deleted]

  has_one :persona, serializer: PanWeb.Api.PlainPersonaView, include: true
  has_one :episode, serializer: PanWeb.Api.PlainEpisodeView, include: true

  def location(gig, conn) do
    api_gig_url(conn, :show, gig)
  end
end


defmodule PanWeb.Api.PlainGigView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "gig"

  location :location
  attributes [:from_in_s, :until_in_s, :comment, :publishing_date, :role, :self_proclaimed,
              :persona_id, :episode_id, :created, :deleted]

  def location(gig, conn) do
    api_gig_url(conn, :show, gig)
  end
end