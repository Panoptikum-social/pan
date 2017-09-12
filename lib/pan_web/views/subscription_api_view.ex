defmodule PanWeb.SubscriptionApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "subscription"

  location :my_subscription_api_url

  attributes [:created, :deleted]

  has_one :podcast, serializer: PanWeb.PlainPodcastApiView, include: false
  has_one :user, serializer: PanWeb.PlainUserApiView, include: false

  def my_subscription_api_url(_like, conn) do
    subscription_api_url(conn, :toggle)
  end
end
