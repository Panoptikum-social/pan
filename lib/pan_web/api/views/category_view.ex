defmodule PanWeb.Api.CategoryView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location(:location)
  attributes([:title])

  has_one(:parent, serializer: PanWeb.Api.PlainCategoryView, include: false)
  has_many(:children, serializer: PanWeb.Api.PlainCategoryView, include: false)

  has_many(:podcasts, serializer: PanWeb.Api.PlainPodcastView, include: false)

  def location(category, conn) do
    api_category_url(conn, :show, category)
  end
end

defmodule PanWeb.Api.PlainCategoryView do
  use PanWeb, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location(:location)
  attributes([:title])

  def location(category, conn) do
    api_category_url(conn, :show, category)
  end
end
