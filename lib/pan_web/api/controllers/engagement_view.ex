defmodule PanWeb.Api.EngagementApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location :engagement_url
  attributes [:from, :until, :comment, :role, :persona_id, :podcast_id]

  has_one :persona, serializer: PanWeb.PlainPersonaApiView, include: true
  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: true

  def engagement_url(engagement, conn) do
    engagement_url(conn, :show, engagement)
  end
end


defmodule PanWeb.Api.PlainEngagmentApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location :engagement_url
  attributes [:from, :until, :comment, :role, :persona_id, :podcast_id]

  def engagement_url(engagement, conn) do
    engagement_url(conn, :show, engagement)
  end
end