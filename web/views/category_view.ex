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


  def render("get_podcasts.json", %{ podcasts_assigned: podcasts_assigned,
                                     podcasts_unassigned: podcasts_unassigned }) do
    %{ podcasts_assigned: Enum.map(podcasts_assigned, &podcast_json/1),
       podcasts_unassigned: Enum.map(podcasts_unassigned, &podcast_json/1 ) }
  end


  def podcast_json(podcast) do
    %{ title:  escape_javascript(podcast.title || " "),
       author: escape_javascript(podcast.author || " ")}
  end
end