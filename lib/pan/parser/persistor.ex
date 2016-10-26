defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller

  def call(map) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    map[:contributors]

#    {:ok ,owner }  = find_or_create_owner(map[:owner])
#    {:ok, podcast} = find_or_create_podcast(map[:podcast], owner.id)
#    {:ok, feed}    = find_or_create_feed(map[:feed], podcast.id)
#    find_or_create_alternate_feeds(alternate_feeds_map, feed.id)
#    persist_contributors(map[:contributors], podcast_id, nil)
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
    for {uuid, alternate_feed_map} <- alternate_feeds_map do
      case Repo.get_by(Pan.AlternateFeed, url: alternate_feed_map[:url])
        nil -> %Pan.AlternateFeed(feed_id: feed_id)
               |> Map.merge(alternate_feed_map)
               |> Repo.insert()
        alternate_feed -> {:ok, alternate_feed}
      end
    end
  end



end


####################

  #  def persist_contributors(xml, podcast_id, episode_id) do
  #    for contributor <- contributors do
  #      if Repo.get_by(Contributor, uri: contributor.uri) == nil do
  #        associate(contributor, podcast)
  #      end
  #    end
  #  end


  # def associate(instance, podcast) do
  #   category = Repo.preload(instance, :podcasts)

  #   category
  #   |> Ecto.Changeset.change()
  #   |> Ecto.Changeset.put_assoc(:podcasts, [podcast | category.podcasts])
  #   |> Repo.update!
  # end
