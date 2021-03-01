defmodule PanWeb.Api.FollowView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "follow"

  location(:location)

  attributes([:created, :deleted])

  has_one(:podcast, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_one(:persona, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_one(:category, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_one(:follower, serializer: PanWeb.Api.PlainUserView, include: false)
  has_one(:user, serializer: PanWeb.Api.PlainUserView, include: false)

  def location(follow, conn) do
    api_follow_url(conn, :show, follow)
  end
end
