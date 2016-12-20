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


  def podcast_list(podcasts) do
    Enum.map(podcasts, fn(podcast) ->
      %{ title:  escape_javascript(podcast.title || " "),
         author: escape_javascript(podcast.author || " ")}
    end)
    |> Poison.encode!
    |> raw
  end
end