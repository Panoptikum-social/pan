defmodule Pan.CategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location :category_api_url
  attributes [:title]

  has_one :parent,    serializer: Pan.PlainCategoryApiView, include: true
  has_many :children, serializer: Pan.PlainCategoryApiView, include: true

  has_many :podcasts, serializer: Pan.PlainPodcastApiView, include: false

  def category_api_url(category, conn) do
    category_api_url(conn, :show, category)
  end
end


defmodule Pan.PlainCategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location :category_api_url
  attributes [:title]

  def category_api_url(category, conn) do
    category_api_url(conn, :show, category)
  end
end