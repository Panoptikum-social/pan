defmodule PanWeb.FollowApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "follow"

  location :my_follow_api_url

  attributes [:created, :deleted]

  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: false
  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: false
  has_one :category, serializer: PanWeb.PlainPersonaApiView, include: false
  has_one :follower, serializer: PanWeb.PlainUserApiView, include: false
  has_one :user, serializer: PanWeb.PlainUserApiView, include: false

  def my_follow_api_url(_like, conn) do
    follow_api_url(conn, :toggle)
  end
end
