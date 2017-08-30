defmodule Pan.CategoryApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  location "/categories/:id"
  attributes [:title]

  has_one :parent,
    serializer: Pan.CategoryApiView,
    include: true,
    field: :parent_id

  has_many :children,
    serializer: Pan.CategoryApiView,
    include: true,
    field: :parent_id
end