defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller

  def call(map) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, :owner])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])

    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok ,owner }  = Pan.Parser.User.find_or_create(map[:owner])
    {:ok, podcast} = Pan.Parser.Podcast.find_or_create(podcast_map, owner.id)
    {:ok, feed}    = Pan.Parser.Feed.find_or_create(feed_map, podcast.id)

    Pan.Parser.AlternateFeed.find_or_create_many(alternate_feeds_map, feed.id)
    Pan.Parser.Contributor.persist_many(map[:contributors], podcast)
    Pan.Parser.Language.persist_many(map[:languages], podcast)
    Pan.Parser.Category.assign_many(map[:categories], podcast)

    if map[:episodes] do
      Pan.Parser.Episode.persist_many(map[:episodes], podcast)
    end

    podcast.id
  end
end