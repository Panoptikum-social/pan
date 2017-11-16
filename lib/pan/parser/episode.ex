defmodule Pan.Parser.Episode do
  use Pan.Web, :controller
  alias Pan.Parser.Contributor
  alias Pan.Parser.Chapter
  alias Pan.Parser.Enclosure
  alias Pan.Parser.Author
  alias Pan.Repo
  require Logger

  def get_or_insert(episode_map, podcast_id) do
    case Repo.get_by(PanWeb.Episode, guid: episode_map.guid, podcast_id: podcast_id) do
      nil ->
        if episode_map[:guid] do
          insert(episode_map, podcast_id)
        else
          case Repo.get_by(PanWeb.Episode, title: episode_map.title || episode_map.subtitle,
                                           podcast_id: podcast_id) do
            nil ->
              insert(episode_map, podcast_id)
            episode ->
              {:exists, episode}
          end
        end
      episode ->
        {:exists, episode}
    end
  end


  def insert(episode_map, podcast_id) do
    # Here comes the line with the initial update time
    PanWeb.Podcast
    |> Repo.get(podcast_id)
    |> PanWeb.Podcast.changeset(%{update_intervall: 10,
                               next_update: Timex.shift(Timex.now(), hours: 10)})
    |> Repo.update()

    %PanWeb.Episode{podcast_id: podcast_id}
    |> Map.merge(episode_map)
    |> Repo.insert()
  end


  def get(episode_map, podcast_id) do
    case Repo.get_by(PanWeb.Episode, guid: episode_map.guid, podcast_id: podcast_id) do
      nil ->
        case Repo.get_by(PanWeb.Episode, title: episode_map.title, podcast_id: podcast_id) do
          nil ->
            {:error, "not_found"}
          episode ->
            {:exists, episode}
        end
      episode ->
        {:exists, episode}
    end
  end


  def persist_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      persist_one(episode_map, podcast)
    end
  end


  def insert_contributors(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      if episode_map[:enclosures] do
        first_enclosure = episode_map.enclosures |> Map.to_list |> List.first |> elem(1)
        fallback_url = if episode_map[:link], do: episode_map.link, else: first_enclosure.url

        plain_episode_map = episode_map
        |> Map.drop([:chapters, :enclosures, :contributors])
        |> Map.put_new(:guid, fallback_url)

        case get(plain_episode_map, podcast.id) do
          {:exists, episode} ->
            Contributor.persist_many(episode_map.contributors, episode)
            Logger.info "\n\e[33m === Updating contributors for episode: #{episode.title} ===\e[0m"

          {:error, "not_found"} ->
            true
        end
      end
    end
  end


  def clean() do
    episodes = Repo.all(PanWeb.Episode)

    for episode <- episodes do
      episode
      |> PanWeb.Episode.changeset(
        %{description: HtmlSanitizeEx2.basic_html_reduced(episode.description),
          summary:     HtmlSanitizeEx2.basic_html_reduced(episode.summary)}
      )
      |> Repo.update()
    end
  end


  # private helpers
  defp persist_one(%{enclosures: enclosures} = episode_map, podcast) do
    first_enclosure = unwrap_first_enclosure(enclosures)
    plain_episode_map = clean_episode(episode_map, first_enclosure.url)

    with {:ok, episode} <- get_or_insert(plain_episode_map, podcast.id) do
      if episode_map[:chapters] do
        get_or_insert_chapters(episode_map.chapters, episode.id)
      end
      get_or_insert_enclosures(enclosures, episode.id)

      Contributor.persist_many(episode_map.contributors, episode)
      Author.get_or_insert_persona_and_gig(episode_map.author, episode, podcast)
      Logger.info "\n\e[33m === Importing new episode: #{episode.title} ===\e[0m"

    else
      {:exists, _episode} ->
        true
    end
  end
  defp persist_one(_episodes_map, _podcast), do: {:error, :no_enclosures}

  defp unwrap_first_enclosure(enclosures) do
    enclosures
    |> Map.to_list
    |> List.first
    |> elem(1)
  end

  defp clean_episode(episode_map, fallback_url) do
    episode_map
    |> Map.drop([:chapters, :enclosures, :contributors])
    |> Map.put_new(:guid, episode_map.link || fallback_url)
  end

  defp get_or_insert_chapters(chapters, episode_id) do
    for {_, chapter_map} <- chapters do
      Chapter.get_or_insert(chapter_map, episode_id)
    end
  end

  defp get_or_insert_enclosures(enclosures, episode_id) do
    for {_, enclosure_map} <- enclosures do
      Enclosure.get_or_insert(enclosure_map, episode_id)
    end
  end
end
