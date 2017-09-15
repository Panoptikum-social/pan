defmodule PanWeb.CategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location :category_api_url
  attributes [:title]

  has_one :parent,    serializer: PanWeb.PlainCategoryApiView, include: false
  has_many :children, serializer: PanWeb.PlainCategoryApiView, include: false

  has_many :podcasts, serializer: PanWeb.PlainPodcastApiView, include: false

  def category_api_url(category, conn) do
    category_api_url(conn, :show, category)
  end
end


defmodule PanWeb.PlainCategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location :category_api_url
  attributes [:title]

  def category_api_url(category, conn) do
    category_api_url(conn, :show, category)
  end
end