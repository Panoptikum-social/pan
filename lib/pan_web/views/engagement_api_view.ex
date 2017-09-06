defmodule PanWeb.EngagementApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location :engagement_api_url
  attributes [:from, :until, :comment, :role, :persona_id, :podcast_id]

  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: true
  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: true

  def engagement_api_url(engagement, conn) do
    engagement_api_url(conn, :show, engagement)
  end
end


defmodule PanWeb.PlainEngagmentApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location :engagement_api_url
  attributes [:from, :until, :comment, :role, :persona_id, :podcast_id]

  def engagement_api_url(engagement, conn) do
    engagement_api_url(conn, :show, engagement)
  end
end