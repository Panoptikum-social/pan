defmodule PanWeb.SearchFrontendView do
  use Pan.Web, :view
  alias Pan.Repo
  alias PanWeb.{Episode, Image, Podcast, Persona}
  import Scrivener.HTML

  def hit_widget(hit, searchstring) do
    %{_source: fields, _type: type, _score: score} = hit

    case type do
      "episodes"   ->
        if episode = Repo.get(Episode, hit._id) do
          episode = Repo.preload(episode, [podcast: :languages, gigs: :persona])

          episode_thumbnail = Repo.get_by(Image, episode_id: episode.id) ||
                              Repo.get_by(Image, podcast_id: episode.podcast_id)

          render("episode.html", episode: fields,
                                 searchstring: searchstring,
                                 podcast_title: episode.podcast.title,
                                 episode_image_title: episode.image_title,
                                 podcast_image_title: episode.podcast.image_title,
                                 podcast_url: podcast_frontend_url(PanWeb.Endpoint, :show, episode.podcast.id),
                                 gigs: episode.gigs,
                                 languages: episode.podcast.languages,
                                 episode_thumbnail: episode_thumbnail,
                                 score: score)
        else
          String.to_integer(hit._id)
          |> Episode.delete_search_index()

          nil
        end
      "podcasts"   ->
        podcast = Repo.get!(Podcast, hit._id)
                  |> Repo.preload([:categories, :languages, engagements: :persona])
        podcast_thumbnail = Repo.get_by(Image, podcast_id: podcast.id)

        render("podcast.html", podcast: fields,
                               searchstring: searchstring,
                               categories: podcast.categories,
                               engagements: podcast.engagements,
                               languages: podcast.languages,
                               podcast_thumbnail: podcast_thumbnail,
                               podcast_image_title: podcast.image_title,
                               score: score)

      "personas"   ->
        persona = Repo.get!(Persona, hit._id)
                  |> Repo.preload(engagements: :podcast)
        persona_thumbnail = Repo.get_by(Image, persona_id: persona.id)

        render("persona.html", persona: fields,
                               engagements: persona.engagements,
                               persona_thumbnail: persona_thumbnail,
                               persona_image_title: persona.image_title,
                               score: score)
      "users"      ->
        render("user.html", user: fields,
                            score: score)
      "categories" ->
        render("category.html", category: fields,
                                score: score)
    end
  end


  def podcast_hit(podcast, searchstring) do
    hit([Title:       podcast[:title],
         Description: podcast[:description],
         Summary:     podcast[:summary]], searchstring, "")
    |> raw()
  end


  def episode_hit(episode, searchstring) do
    hit([Title:       episode[:title],
         Subtitle:    episode[:subtitle],
         Description: episode[:description],
         Summary:     episode[:summary],
         Shownotes:   episode[:shownotes]], searchstring, "")
    |> raw
  end


  def hit([head | tail], searchstring, output) do
    {type, content} = head

    regex = Regex.escape(searchstring)

    case content != nil and String.match?(content, ~r/#{regex}/i) do
      true ->
        hit(tail, searchstring, output <> "<i>" <> Atom.to_string(type) <> ":</i> " <>
                                highlight(content, searchstring) <> "<br/>")
      false ->
        hit(tail, searchstring, output)
    end
  end

  def hit([], _searchstring, output) do
    output
  end


  def highlight(result, searchstring) do
    regex = Regex.escape(searchstring)

    [left, match, right] =  Regex.split(~r/#{regex}/i, result, [include_captures: true, parts: 2])

    left = left
           |> HtmlSanitizeEx.strip_tags
           |> String.reverse
           |> truncate_string(60)
           |> String.reverse
    right = right
            |> HtmlSanitizeEx.strip_tags
            |> truncate_string(60)

    left <> "<b>" <> match <> "</b>" <> right
  end
end