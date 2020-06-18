defmodule PanWeb.Api.UserView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location(:location)
  attributes([:name, :podcaster, :share_subscriptions, :share_follows])

  has_many(:podcasts_i_follow, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_many(:podcasts_i_subscribed, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_many(:users_i_like, serializer: PanWeb.Api.PlainUserView, include: false)
  has_many(:podcasts_i_follow, serializer: PanWeb.Api.PlainPodcastView, include: false)
  has_many(:categories_i_like, serializer: PanWeb.Api.PlainCategoryView, include: false)

  def location(user, conn) do
    api_user_url(conn, :show, user)
  end
end

defmodule PanWeb.Api.PlainUserView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location(:location)
  attributes([:name, :podcaster, :share_subscriptions, :share_follows])

  def location(user, conn) do
    api_user_url(conn, :show, user)
  end
end

defmodule PanWeb.Api.MyUserView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location(:location)

  attributes([
    :name,
    :username,
    :email,
    :admin,
    :podcaster,
    :email_confirmed,
    :share_subscriptions,
    :share_follows,
    :pro_until,
    :billing_address,
    :payment_reference,
    :paper_bill
  ])

  has_many(:personas, serializer: PanWeb.Api.PlainPersonaView, include: false)

  def location(_user, conn) do
    api_user_url(conn, :my)
  end
end
