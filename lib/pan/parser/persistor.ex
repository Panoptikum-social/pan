defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller
  alias Pan.Repo


  def initial_import(map) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, :owner, :categories])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]


    {:ok ,owner }  = Pan.Parser.User.get_or_insert(map[:owner])
    {:ok, podcast} = Pan.Parser.Podcast.get_or_insert(podcast_map, owner.id)
    {:ok, feed}    = Pan.Parser.Feed.get_or_insert(feed_map, podcast.id)

    Pan.Parser.Category.persist_many(map[:categories], podcast)
    Pan.Parser.AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)
    Pan.Parser.Contributor.persist_many(map[:contributors], podcast)
    Pan.Parser.Language.persist_many(map[:languages], podcast)

    if map[:episodes] do
      Pan.Parser.Episode.persist_many(map[:episodes], podcast)
    end

    podcast.id
  end


  def delta_import(map, podcast_id) do
    podcast = Repo.get!(Pan.Podcast, podcast_id)
    map = Map.put_new(map, :last_build_date, Ecto.DateTime.utc)

    unless map[:last_build_date] == podcast.last_build_date do
      if map[:episodes] do
        Pan.Parser.Episode.insert_newbies(map[:episodes], podcast)
      end

      Pan.Podcast.changeset(podcast, %{ last_build_date: map[:last_build_date] })
      |> Repo.update()
    end
  end


def fix_owner(map, podcast_id) do
    podcast = Repo.get!(Pan.Podcast, podcast_id)
    map = Map.put_new(map, :last_build_date, Ecto.DateTime.utc)

    {:ok, owner }  = Pan.Parser.User.get_or_insert(map[:owner])

    Pan.Podcast.changeset(podcast, %{owner_id: owner.id })
    |> Repo.update()
  end
end