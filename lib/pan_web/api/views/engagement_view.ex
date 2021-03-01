defmodule PanWeb.Api.EngagementView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location(:location)
  attributes([:from, :until, :comment, :role, :persona_id, :podcast_id])

  has_one(:persona, serializer: PanWeb.Api.PlainPersonaView, include: true)
  has_one(:podcast, serializer: PanWeb.Api.PlainPodcastView, include: true)

  def location(engagement, conn) do
    api_engagement_url(conn, :show, engagement)
  end
end

defmodule PanWeb.Api.PlainEngagmentView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "engagement"

  location(:location)
  attributes([:from, :until, :comment, :role, :persona_id, :podcast_id])

  def location(engagement, conn) do
    api_engagement_url(conn, :show, engagement)
  end
end
