defmodule Pan.SearchFrontendView do
  use Pan.Web, :view
  import Scrivener.HTML

  def podcast_hits(podcast, searchstring) do
    if podcast.blocked == true do
      "This podcast may not be published here."
      |> raw
    else
      hit([Title: podcast.title,
           Author: podcast.author,
           Description: podcast.description,
           Summary: podcast.summary], searchstring, "")
      |> raw
    end
  end


  def episode_hits(episode, searchstring) do
    if episode.podcast.blocked == true do
      "This episode may not be published here."
      |> raw
    else
      hit([Title: episode.title,
           Subtitle: episode.subtitle,
           Description: episode.description,
           Summary: episode.summary,
           Author: episode.author,
           Shownotes: episode.shownotes], searchstring, "")
      |> raw
    end
  end


  def hit([head | tail], searchstring, output) do
    {type, content} = head

    case content != nil and String.match?(content, ~r/#{searchstring}/i) do
      true ->
        hit(tail, searchstring, output <> "<b>" <> Atom.to_string(type) <> ":</b> " <>
                                highlight(content, searchstring) <> "<br/>")
      false ->
        hit(tail, searchstring, output)
    end
  end

  def hit([], _searchstring, output) do
    output
  end


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
  end
end