defmodule Pan.Parser.Persistor do
  alias Pan.Repo
  import Pan.Parser.MyDateTime, only: [now: 0]

  alias Pan.Parser.{
    AlternateFeed,
    Author,
    Category,
    Contributor,
    Episode,
    Feed,
    Language,
    Podcast,
    PodcastContributor
  }

  def initial_import(map, _url \\ nil) do
    podcast_map =
      Map.drop(map, [
        :episodes,
        :feed,
        :contributors,
        :languages,
        :categories,
        "owner",
        :categories,
        "author",
        "managing_editor"
      ])

    feed_map = Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok, podcast} = Podcast.get_or_insert(podcast_map)
    Author.get_or_insert_persona_and_engagement(map["author"], podcast.id)

    {:ok, feed} = Feed.get_or_insert(feed_map, podcast.id)

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.persist_many(map[:languages], podcast)

    map["owner"] && PodcastContributor.get_or_insert(map["owner"], "owner", podcast.id)

    map["managing_editor"] &&
      PodcastContributor.get_or_insert(map["managing_editor"], "managing editor", podcast.id)

    Contributor.persist_many(map[:contributors], podcast)

    if map[:episodes] do
      Episode.persist_many(map[:episodes], podcast)

      PanWeb.Podcast.changeset(podcast)
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    end

    podcast.id
  end

  def delta_import(map, podcast) do
    map = Map.put_new(map, :last_build_date, now())

    if map.last_build_date != podcast.last_build_date do
      if map[:episodes], do: Episode.persist_many(map.episodes, podcast)
      Feed.update_with_redirect_target(podcast.id, map[:new_feed_url])

      PanWeb.Podcast.changeset(podcast, %{last_build_date: map.last_build_date})
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    else
      {:ok, :nothing_to_do}
    end
  end

  def update_from_feed(map, podcast) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{podcast.id}", %{
      content: "Updating from feed"
    })

    podcast_map =
      Map.drop(map, [
        :episodes,
        :feed,
        :contributors,
        :languages,
        :categories,
        "owner",
        :categories,
        "author",
        "managing_editor"
      ])

    feed_map = Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok, podcast} =
      PanWeb.Podcast.changeset(podcast, podcast_map)
      |> Repo.update()

    PodcastContributor.delete_role(podcast.id, "owner")
    map["owner"] && PodcastContributor.get_or_insert(map["owner"], "owner", podcast.id)

    map["author"] && Author.get_or_insert_persona_and_engagement(map["author"], podcast.id)

    PodcastContributor.delete_role(podcast.id, "managing_editor")

    map["managing_editor"] &&
      PodcastContributor.get_or_insert(map["managing_editor"], "managing editor", podcast.id)

    {:ok, feed} = Feed.get_by_podcast_id(podcast.id)

    if feed.self_link_url != feed_map[:self_link_url] do
      Feed.update_with_redirect_target(podcast.id, feed_map[:self_link_url])
    end

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.delete_for_podcast(podcast.id)
    Language.persist_many(map[:languages], podcast)

    PodcastContributor.delete_role(podcast.id, "contributor")
    Contributor.persist_many(map[:contributors], podcast)

    map[:episodes] && Episode.update_from_feed_many(map[:episodes], podcast)

    PanWeb.Podcast.changeset(podcast)
    |> PanWeb.Podcast.update_counters()
    |> Repo.update()

    {:ok, :podcast_updated}
  end

  def contributor_import(map, podcast_id) do
    podcast = Repo.get!(PanWeb.Podcast, podcast_id)

    if map[:episodes] do
      Episode.insert_contributors(map[:episodes], podcast)
    end
  end
end
