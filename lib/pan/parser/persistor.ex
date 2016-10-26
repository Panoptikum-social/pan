defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller

  def call(map) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok ,owner }  = find_or_create_owner(map[:owner])
    {:ok, podcast} = find_or_create_podcast(podcast_map, owner.id)
    {:ok, feed}    = find_or_create_feed(feed_map, podcast.id)
    find_or_create_alternate_feeds(alternate_feeds_map, feed.id)
    persist_contributors(map[:contributors], podcast)
    persist_languages(map[:languages], podcast)
    assign_categories(map[:categories], podcast)
    persist_episodes(map[:episodes], podcast)
  end


  def find_or_create_owner(owner_map) do
    case Repo.get_by(Pan.User, email: owner_map[:email]) do
      nil -> %Pan.User{}
             |> Map.merge(owner_map)
             |> Map.merge(%{username: owner_map[:name]})
             |> Repo.insert()
      user -> {:ok, user}
    end
  end


  def find_or_create_podcast(podcast_map, owner_id) do
    case Repo.get_by(Pan.Podcast, title: podcast_map[:title]) do
      nil -> %Pan.Podcast{owner_id: owner_id}
             |> Map.merge(podcast_map)
             |> Repo.insert()
      podcast -> {:ok, podcast}
    end
  end


  def find_or_create_feed(feed_map, podcast_id) do
    case Repo.get_by(Pan.Feed, self_link_url: feed_map[:self_link_url]) do
      nil -> %Pan.Feed{podcast_id: podcast_id}
             |> Map.merge(feed_map)
             |> Repo.insert()
      feed -> {:ok, feed}
    end
  end


  def find_or_create_alternate_feeds(alternate_feeds_map, feed_id) do
    for {_, alternate_feed_map} <- alternate_feeds_map do
      case Repo.get_by(Pan.AlternateFeed, url: alternate_feed_map[:url]) do
        nil -> %Pan.AlternateFeed{feed_id: feed_id}
               |> Map.merge(alternate_feed_map)
               |> Repo.insert()
        alternate_feed -> {:ok, alternate_feed}
      end
    end
  end


  def find_or_create_contributor(contributor_map) do
    case Repo.get_by(Pan.Contributor, uri: contributor_map[:uri]) do
      nil -> %Pan.Contributor{}
             |> Map.merge(contributor_map)
             |> Repo.insert()
      contributor -> {:ok, contributor}
    end
  end


  def persist_contributors(contributors_map, instance) do
    contributors =
      Enum.map contributors_map, fn({_, contributor_map}) ->
        elem(find_or_create_contributor(contributor_map), 1)
      end

    Repo.preload(instance, :contributors)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:contributors, contributors)
    |> Repo.update!
  end


  def find_or_create_language(shortcode) do
    case Repo.get_by(Pan.Language, shortcode: shortcode) do
      nil -> %Pan.Language{shortcode: shortcode,
                           name: UUID.uuid1()}
             |> Repo.insert
      language -> {:ok, language}
    end
  end


  def persist_languages(languages_map, podcast) do
    languages =
      Enum.map languages_map, fn({_, language_map}) ->
        elem(find_or_create_language(language_map), 1)
      end

    Repo.preload(podcast, :languages)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:languages, languages)
    |> Repo.update!
  end


  def assign_categories(categories_map, podcast) do
    categories =
      Enum.map categories_map, fn({id, _}) ->
        Repo.get(Pan.Category, id)
      end

    Repo.preload(podcast, :categories)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:categories, categories)
    |> Repo.update!
  end


  def persist_episodes(episodes_map, podcast) do
    for {_, episode_map} <- episodes_map do
      plain_episode_map = Map.drop(episode_map, [:chapters, :enclosures, :contributors])
      {:ok, episode} = find_or_create_episode(plain_episode_map, podcast.id)

      for chapter_map <- episode_map[:chapters] do
        find_or_create_chapter(chapter_map, episode.id)
      end

      for enclosure_map <- episode_map[:enclosures] do
        find_or_create_enclosure(enclosure_map, episode.id)
      end

      for contributor_map <- episode_map[:contributors] do
        persist_contributors(contributor_map, episode.id)
      end
    end
  end


  def find_or_create_episode(episode_map, podcast_id) do
    Map.put_new(episode_map, :guid, episode_map[:link])

    case Repo.get_by(Pan.Episode, guid: episode_map[:guid],
                                  link: episode_map[:link]) do
      nil ->
        %Pan.Episode{podcast_id: podcast_id}
        |> Map.merge(episode_map)
        |> Repo.insert()
      episode ->
        {:ok, episode}
    end
  end


  def find_or_create_chapter(chapter_map, episode_id) do
    case Repo.get_by(Pan.Chapter, episode_id: episode_id,
                                  start:      chapter_map[:start]) do
      nil ->
        %Pan.Chapter{episode_id: episode_id}
        |> Map.merge(chapter_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end


  def find_or_create_enclosure(enclosure_map, episode_id) do
    case Repo.get_by(Pan.Enclosure, episode_id: episode_id,
                                    guid:       enclosure_map[:guid],
                                    url:        enclosure_map[:url]) do
      nil ->
        %Pan.Enclosure{episode_id: episode_id}
        |> Map.merge(enclosure_map)
        |> Repo.insert()
      chapter ->
        {:ok, chapter}
    end
  end
end