defmodule Pan.Parser.Episode do
  use Pan.Web, :controller
  alias Pan.Parser.Contributor
  alias Pan.Parser.Chapter
  alias Pan.Parser.Enclosure

  def get_or_insert(episode_map, podcast_id) do
    case Repo.get_by(Pan.Episode, guid: episode_map[:guid], podcast_id: podcast_id) do
      nil ->
        case Repo.get_by(Pan.Episode, title: episode_map[:title], podcast_id: podcast_id) do
          nil ->
            %Pan.Episode{podcast_id: podcast_id}
            |> Map.merge(episode_map)
            |> Repo.insert()
          episode ->
            {:ok, episode}
        end
      episode ->
        {:ok, episode}
    end
  end


  def persist_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do

      first_enclosure =
        if episode_map[:enclosures] do
          episode_map[:enclosures]
          |> Map.to_list
          |> List.first
          |> elem(1)
        else
          %{url: ""}
        end

      fallback_url =
        if episode_map[:link] != nil do
          episode_map[:link]
        else
          first_enclosure[:url]
        end

      plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
                          |> Map.put_new(:guid, fallback_url)

      if plain_episode_map[:guid] do
        {:ok, episode} = get_or_insert(plain_episode_map, podcast.id)

        if episode_map[:chapters] do
          for {_, chapter_map} <- episode_map[:chapters] do
            Chapter.get_or_insert(chapter_map, episode.id)
          end
        end

        if episode_map[:enclosures] do
          for {_, enclosure_map} <- episode_map[:enclosures] do
            Enclosure.get_or_insert(enclosure_map, episode.id)
          end
        end

        Contributor.persist_many(episode_map[:contributors], episode)
      end
    end
  end


  def insert_newbies(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      if episode_map[:enclosures] do
        first_enclosure = episode_map[:enclosures] |> Map.to_list |> List.first |> elem(1)
        fallback_url = if episode_map[:link], do: episode_map[:link], else: first_enclosure[:url]

        plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
                            |> Map.put_new(:guid, fallback_url)

        case is_new_then_persist(plain_episode_map, podcast.id) do
          {:ok, episode} ->
            if episode_map[:chapters] do
              for {_, chapter_map} <- episode_map[:chapters] do
                Chapter.get_or_insert(chapter_map, episode.id)
              end
            end

            if episode_map[:enclosures] do
              for {_, enclosure_map} <- episode_map[:enclosures] do
                Enclosure.get_or_insert(enclosure_map, episode.id)
              end
            end

            Contributor.persist_many(episode_map[:contributors], episode)
            IO.puts "\n\e[33m === new Episode:  " <> episode.title <> " ===\e[0m"

          {:exists, _episode} ->
            # IO.puts "\n\e[92m === Episode exists:  " <> episode.title <> " ===\e[0m"
            true
        end
      end
    end
  end


  def is_new_then_persist(episode_map, podcast_id) do
    case Repo.get_by(Pan.Episode, guid: episode_map[:guid], podcast_id: podcast_id) do
      nil ->
        %Pan.Episode{podcast_id: podcast_id}
        |> Map.merge(episode_map)
        |> Repo.insert()
      episode ->
        {:exists, episode}
    end
  end



  def clean() do
    episodes = Pan.Repo.all(Pan.Episode)

    for episode <- episodes do
      Pan.Episode.changeset(episode, %{description: HtmlSanitizeEx2.basic_html_reduced(episode.description),
                                       summary:     HtmlSanitizeEx2.basic_html_reduced(episode.summary)})
      |> Repo.update()
    end
  end
end