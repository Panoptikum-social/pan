defmodule Pan.SearchFrontendView do
  use Pan.Web, :view

  def highlight(result, searchstring) do
    [left, match, right] =  Regex.split(~r/#{searchstring}/i, result, [include_captures: true, parts: 2])

    left = left
           |> HtmlSanitizeEx.strip_tags
           |> String.reverse
           |> C.String.truncate(50)
           |> String.reverse
    right = right
            |> HtmlSanitizeEx.strip_tags
            |> C.String.truncate(50)

    left <> "<b><span class='bg-success'>" <> match <> "</span></b>" <> right
    |> raw
  end
end
