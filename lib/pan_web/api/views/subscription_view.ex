defmodule PanWeb.Api.SubscriptionView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "subscription"

  location(:location)

  attributes([:created, :deleted])

  has_one(:podcast, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_one(:user, serializer: PanWeb.Api.PlainUserView, include: false)

  def location(_like, conn) do
    api_subscription_url(conn, :toggle)
  end
end
