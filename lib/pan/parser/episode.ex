defmodule Pan.Parser.Episode do
  use Pan.Web, :controller

  def find_or_create(episode_map, podcast_id) do
    Map.put_new(episode_map, :guid, episode_map[:link])

    case Repo.get_by(Pan.Episode,
#FIXME!                                  guid: episode_map[:guid],
                                  link: episode_map[:link]) do
      nil ->
        %Pan.Episode{podcast_id: podcast_id}
        |> Map.merge(episode_map)
        |> Repo.insert()
      episode ->
        {:ok, episode}
    end
  end


  def persist_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
      {:ok, episode} = find_or_create(plain_episode_map, podcast.id)

      if episode_map[:chapters] do
        for {_, chapter_map} <- episode_map[:chapters] do
          Pan.Parser.Chapter.find_or_create(chapter_map, episode.id)
        end
      end

      for {_, enclosure_map} <- episode_map[:enclosures] do
        Pan.Parser.Enclosure.find_or_create(enclosure_map, episode.id)
      end

      Pan.Parser.Contributor.persist_many(episode_map[:contributors], episode)
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