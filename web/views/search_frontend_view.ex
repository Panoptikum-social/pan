defmodule Pan.SearchFrontendView do
  use Pan.Web, :view

  def highlight(result, searchstring) do
    [left, right] =  String.split(String.downcase(result), String.downcase(searchstring), parts: 2)

    left = left
           |> HtmlSanitizeEx.strip_tags
           |> String.reverse
           |> C.String.truncate(50)
           |> String.reverse
    right = right
            |> HtmlSanitizeEx.strip_tags
            |> C.String.truncate(50)

    left <> "<b><span class='text-danger'>" <> searchstring <> "</span></b>" <> right
    |> raw
  end
end
