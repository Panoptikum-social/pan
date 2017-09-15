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


defmodule PanWeb.MyUserApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "user"

  location :my_user_api_url
  attributes [:name, :username, :email, :admin, :podcaster, :email_confirmed, :share_subscriptions,
              :share_follows, :pro_until, :billing_address, :payment_reference, :paper_bill]

  has_many :personas, serializer: PanWeb.PlainPersonaApiView, include: false

  def my_user_api_url(_user, conn) do
    user_api_url(conn, :my)
  end
end
