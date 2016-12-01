defmodule Pan.CategoryView do
  use Pan.Web, :view

  def category_tree(categories) do
    Enum.map(categories, fn(category) ->
      %{ categoryId: category.id,
         text: category.title,
         nodes: Enum.map(category.children, fn(category) -> %{text: category.title,
                                                              categoryId: category.id} end),
         state: %{ expanded: false }
      }
    end)
    |> Poison.encode!
    |> raw
  end
end