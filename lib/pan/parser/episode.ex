defmodule Pan.Parser.Episode do
  import Ecto.Query
  alias Pan.Repo
  alias Pan.Parser.{Author, Chapter, Contributor, Enclosure}
  require Logger
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  def get_or_insert(episode_map, podcast_id) do
    case get_episode_by_guid_or_title_or_subtitle(episode_map, podcast_id) do
      nil ->
        insert(episode_map, podcast_id)

      episode ->
        {:exists, episode}
    end
  end

  def get(episode_map, podcast_id) do
    case get_episode_by_guid_or_title_or_subtitle(episode_map, podcast_id) do
      nil ->
        {:error, "not_found"}

      episode ->
        {:exists, episode}
    end
  end

  def get_episode_by_guid_or_title_or_subtitle(episode_map, podcast_id) do
    if episode_map[:guid] do
      Repo.get_by(PanWeb.Episode, guid: episode_map.guid, podcast_id: podcast_id)
    else
      Repo.get_by(PanWeb.Episode,
        title: episode_map[:title] || episode_map.subtitle,
        podcast_id: podcast_id
      )
    end
  end

  def insert_or_update(episode_map, podcast_id) do
    case get_episode_by_guid_or_title_or_subtitle(episode_map, podcast_id) do
      nil ->
        insert(episode_map, podcast_id)

      episode ->
        ### Here is place to remove info from episodes, that is no longer in the feed
        episode_map = Map.put_new(episode_map, :image_url, nil)

        episode
        |> PanWeb.Episode.changeset(episode_map)
        # forces timestamp to update
        |> Repo.update(force: true)
    end
  end

  def insert(episode_map, podcast_id) do
    # Here comes the line with the initial update time
    PanWeb.Podcast
    |> Repo.get(podcast_id)
    |> PanWeb.Podcast.changeset(%{
      update_intervall: 10,
      next_update: time_shift(now(), hours: 10)
    })
    |> Repo.update()

    episode_map =
      episode_map
      |> Map.put_new(:publishing_date, now())
      |> Map.put_new(:title, "No title provided")

    %PanWeb.Episode{podcast_id: podcast_id}
    |> Map.merge(episode_map)
    |> Repo.insert()
  end

  def persist_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      persist_one(episode_map, podcast)
    end
  end

  def update_from_feed_many(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map, do: update_from_feed_one(episode_map, podcast)

    # delete deprecated episodes
    episodes =
      from(e in PanWeb.Episode,
        where: e.podcast_id == ^podcast.id and e.updated_at < ^time_shift(now(), hours: -1)
      )
      |> Repo.all()

    for episode <- episodes, do: Repo.delete(episode)
  end

  def insert_contributors(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      if episode_map[:enclosures] do
        first_enclosure = unwrap_first_enclosure(episode_map.enclosures)
        plain_episode_map = clean_episode(episode_map, first_enclosure.url)

        case get(plain_episode_map, podcast.id) do
          {:exists, episode} ->
            Contributor.persist_many(episode_map.contributors, episode)
            Logger.info("=== Updating contributors for episode: #{episode.title} ===")

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
      |> PanWeb.Episode.changeset(%{
        description: HtmlSanitizeEx2.basic_html_reduced(episode.description),
        summary: HtmlSanitizeEx2.basic_html_reduced(episode.summary)
      })
      |> Repo.update()
    end
  end

  # private helpers
  defp persist_one(%{enclosures: enclosures} = episode_map, podcast) do
    first_enclosure = unwrap_first_enclosure(enclosures)
    plain_episode_map = clean_episode(episode_map, first_enclosure.url)

    case get_or_insert(plain_episode_map, podcast.id) do
      {:ok, episode} ->
        get_or_insert_enclosures(enclosures, episode.id)

        if episode_map[:chapters], do: get_or_insert_chapters(episode_map.chapters, episode.id)

        if episode_map[:contributors] do
          Contributor.persist_many(episode_map.contributors, episode)
        end

        if episode_map[:author] do
          Author.get_or_insert_persona_and_gig(episode_map.author, episode, podcast)
        end

        Logger.info("=== Importing new episode: #{episode.title} ===")

      {:exists, _episode} ->
        true
    end
  end

  defp persist_one(_episodes_map, _podcast), do: {:error, :no_enclosures}

  defp unwrap_first_enclosure(enclosures) do
    enclosures
    |> Map.to_list()
    |> List.first()
    |> elem(1)
  end

  defp clean_episode(episode_map, fallback_url) do
    episode_map
    |> Map.drop([:chapters, :enclosures, :contributors])
    |> Map.put_new(:guid, episode_map[:link] || fallback_url)
  end

  defp get_or_insert_chapters(chapters, episode_id) do
    for {_, chapter_map} <- chapters do
      Chapter.get_or_insert(chapter_map, episode_id)
    end
  end

  defp insert_or_touch_chapters(chapters, episode_id) do
    for {_, chapter_map} <- chapters do
      Chapter.insert_or_touch(chapter_map, episode_id)
    end

    # delete deprecated chapters
    from(c in PanWeb.Chapter,
      where:
        c.episode_id == ^episode_id and
          c.updated_at < ^time_shift(now(), hours: -1)
    )
    |> Repo.delete_all()
  end

  defp get_or_insert_enclosures(enclosures, episode_id) do
    for {_, enclosure_map} <- enclosures do
      Enclosure.get_or_insert(enclosure_map, episode_id)
    end
  end

  defp update_from_feed_one(%{enclosures: enclosures} = episode_map, podcast) do
    first_enclosure = unwrap_first_enclosure(enclosures)
    plain_episode_map = clean_episode(episode_map, first_enclosure.url)

    with {:ok, episode} <- insert_or_update(plain_episode_map, podcast.id) do
      get_or_insert_enclosures(enclosures, episode.id)

      if episode_map[:chapters] do
        insert_or_touch_chapters(episode_map.chapters, episode.id)
      end

      if episode_map[:contributors] do
        Contributor.delete_role(episode.id, "contributor")
        Contributor.persist_many(episode_map.contributors, episode)
      end

      if episode_map[:author] do
        Author.get_or_insert_persona_and_gig(episode_map.author, episode, podcast)
      end

      Logger.info("=== Updating episode: #{episode.title} ===")
    end
  end

  defp update_from_feed_one(_episodes_map, _podcast), do: {:error, :no_enclosures}
end
