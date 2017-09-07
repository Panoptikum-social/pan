defmodule Pan.Parser.Persistor do
  use Pan.Web, :controller
  alias Pan.Repo
  alias Pan.Parser.Author
  alias Pan.Parser.Podcast
  alias Pan.Parser.Episode
  alias Pan.Parser.Contributor
  alias Pan.Parser.Feed
  alias Pan.Parser.Category
  alias Pan.Parser.AlternateFeed
  alias Pan.Parser.Language
  alias Pan.Parser.Owner


  def initial_import(map, _url \\ nil) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, :owner, :categories,
                                 :author])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    # if Application.get_env(:pan, :environment) == "dev", do: IO.inspect podcast_map

    {:ok, podcast} = Podcast.get_or_insert(podcast_map)
    Author.get_or_insert_persona_and_engagement(map[:author], podcast.id)

    {:ok, feed}    = Feed.get_or_insert(feed_map, podcast.id)

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.persist_many(map[:languages], podcast)

    if map[:owner] do
      Owner.get_or_insert(map[:owner], podcast.id)
    end

    Contributor.persist_many(map[:contributors], podcast)

    if map[:episodes] do
      Episode.persist_many(map[:episodes], podcast)
    end

    podcast.id
  end


  def delta_import(map, podcast_id) do
    podcast = Repo.get!(PanWeb.Podcast, podcast_id)
    map = Map.put_new(map, :last_build_date, NaiveDateTime.utc_now())

    unless map[:last_build_date] == podcast.last_build_date do
      if map[:episodes] do
        Episode.persist_many(map[:episodes], podcast)
      end

      PanWeb.Podcast.changeset(podcast, %{last_build_date: map[:last_build_date]})
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    end
  end


  def contributor_import(map, podcast_id) do
    podcast = Repo.get!(PanWeb.Podcast, podcast_id)

    if map[:episodes] do
      Episode.insert_contributors(map[:episodes], podcast)
    end
  end
end