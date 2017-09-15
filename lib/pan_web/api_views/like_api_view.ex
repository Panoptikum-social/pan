defmodule PanWeb.LikeApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "like"

  location :my_like_api_url

  attributes [:created, :deleted]

  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: false
  has_one :episode, serializer: PanWeb.PlainEpisodeApiView, include: false
  has_one :chapter, serializer: PanWeb.PlainChapterApiView, include: false
  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: false
  has_one :category, serializer: PanWeb.PlainPersonaApiView, include: false
  has_one :enjoyer, serializer: PanWeb.PlainUserApiView, include: false
  has_one :user, serializer: PanWeb.PlainUserApiView, include: false

  def my_like_api_url(_like, conn) do
    like_api_url(conn, :toggle)
  end
end
