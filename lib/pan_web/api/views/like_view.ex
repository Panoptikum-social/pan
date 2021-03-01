defmodule PanWeb.Api.LikeView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "like"

  location(:location)

  attributes([:created, :deleted])

  has_one(:podcast, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_one(:episode, serializer: PanWeb.Api.PlainEpisodeView, include: false)
  has_one(:chapter, serializer: PanWeb.Api.PlainChapterView, include: false)
  has_one(:persona, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_one(:category, serializer: PanWeb.Api.PlainPersonaView, include: false)
  has_one(:enjoyer, serializer: PanWeb.Api.PlainUserView, include: false)
  has_one(:user, serializer: PanWeb.Api.PlainUserView, include: false)

  def location(_like, conn) do
    api_like_url(conn, :toggle)
  end
end
