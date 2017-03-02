defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller
  alias Pan.Repo


  def initial_import(map) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, :owner, :categories,
                                 :author])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok, podcast} = Pan.Parser.Podcast.get_or_insert(podcast_map)
    Pan.Parser.Author.get_or_insert_into_podcast(map[:author], podcast.id)

    {:ok, feed}    = Pan.Parser.Feed.get_or_insert(feed_map, podcast.id)

    Pan.Parser.Category.persist_many(map[:categories], podcast)
    Pan.Parser.AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)
    Pan.Parser.Language.persist_many(map[:languages], podcast)

    Pan.Parser.Owner.get_or_insert(map[:owner], podcast.id)
    Pan.Parser.Contributor.persist_many(map[:contributors], podcast)

    if map[:episodes] do
      Pan.Parser.Episode.persist_many(map[:episodes], podcast)
    end

    podcast.id
  end


  def delta_import(map, podcast_id) do
    podcast = Repo.get!(Pan.Podcast, podcast_id)
    map = Map.put_new(map, :last_build_date, NaiveDateTime.utc_now())

    unless map[:last_build_date] == podcast.last_build_date do
      if map[:episodes] do
        Pan.Parser.Episode.persist_many(map[:episodes], podcast)
      end

      Pan.Podcast.changeset(podcast, %{last_build_date: map[:last_build_date]})
      |> Repo.update()
    end
  end


  def contributor_import(map, podcast_id) do
    podcast = Repo.get!(Pan.Podcast, podcast_id)

    if map[:episodes] do
      Pan.Parser.Episode.insert_contributors(map[:episodes], podcast)
    end
  end
end