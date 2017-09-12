defmodule PanWeb.UserApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location :user_api_url
  attributes [:name, :podcaster, :share_subscriptions, :share_follows]

  has_many :podcasts_i_follow, serializer: PanWeb.PlainPodcastApiView, include: false
  has_many :podcasts_i_subscribed, serializer: PanWeb.PlainPodcastApiView, include: false
  has_many :users_i_like, serializer: PanWeb.PlainUserApiView, include: false
  has_many :podcasts_i_follow, serializer: PanWeb.PlainPodcastApiView, include: false
  has_many :categories_i_like, serializer: PanWeb.PlainCategoryApiView, include: false

  def user_api_url(user, conn) do
    user_api_url(conn, :show, user)
  end
end


defmodule PanWeb.PlainUserApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location :user_api_url
  attributes [:name, :podcaster, :share_subscriptions, :share_follows]

  def user_api_url(user, conn) do
    user_api_url(conn, :show, user)
  end
end
