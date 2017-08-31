defmodule Pan.CategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location "/categories/:id"
  attributes [:title]

  has_one :parent,    serializer: Pan.PlainCategoryApiView, include: true
  has_many :children, serializer: Pan.PlainCategoryApiView, include: true

  has_many :podcasts, serializer: Pan.ReducedPodcastApiView, include: true
end

defmodule Pan.PlainCategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "category"

  location "/categories/:id"
  attributes [:title]
end