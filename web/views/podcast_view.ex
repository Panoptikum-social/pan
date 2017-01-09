defmodule Pan.PodcastView do
  use Pan.Web, :view

  def podcasts_json(podcasts) do
    Enum.map(podcasts, &podcast_json/1)
    |> Poison.encode!
    |> raw
  end


  def podcast_json(podcast) do
    %{ title:         ej(podcast.title),
       author:        ej(podcast.author),
       id:            podcast.id,
       website:       podcast.website,
       update_paused: podcast.update_paused,
       feed:          List.first(podcast.feeds).id }
  end

  def ej(nil), do: " "
  def ej(string), do: escape_javascript(string)
end