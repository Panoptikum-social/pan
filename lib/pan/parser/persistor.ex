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
  alias Pan.Parser.PodcastContributor


  def initial_import(map, _url \\ nil) do
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, "owner", :categories,
                                 "author", "managing_editor"])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok, podcast} = Podcast.get_or_insert(podcast_map)
    Author.get_or_insert_persona_and_engagement(map["author"], podcast.id)

    {:ok, feed}    = Feed.get_or_insert(feed_map, podcast.id)

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.persist_many(map[:languages], podcast)

    map["owner"] && PodcastContributor.get_or_insert(map["owner"], "owner", podcast.id)

    map["managing_editor"] &&
      PodcastContributor.get_or_insert(map["managing_editor"], "managing editor", podcast.id)

    Contributor.persist_many(map[:contributors], podcast)

    map[:episodes] && Episode.persist_many(map[:episodes], podcast)

    podcast
    |> PanWeb.Podcast.changeset()
    |> PanWeb.Podcast.update_counters()
    |> Repo.update()

    podcast.id
  end


  def delta_import(map, podcast_id) do
    podcast = Repo.get!(PanWeb.Podcast, podcast_id)
    map = Map.put_new(map, :last_build_date, NaiveDateTime.utc_now())

    if map.last_build_date != podcast.last_build_date do
      if map[:episodes] do
        Episode.persist_many(map.episodes, podcast)
      end

      Feed.update_with_redirect_target(podcast_id, map[:new_feed_url])

      podcast
      |> PanWeb.Podcast.changeset(%{last_build_date: map.last_build_date})
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    else
      {:ok, :nothing_to_do}
    end
  end


  def update_from_feed(map, podcast_id) do
    PanWeb.Endpoint.broadcast("podcasts:" <> Integer.to_string(podcast_id),
                              "notification", %{content: "<i class='fa fa-refresh'></i> <i class='fa fa-podcast'></i>...",
                                                type: "success"})
    podcast_map = Map.drop(map, [:episodes, :feed, :contributors,
                                 :languages, :categories, "owner", :categories,
                                 "author", "managing_editor"])
    feed_map =    Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    {:ok, podcast} = Podcast.update(podcast_map, podcast_id)

    PodcastContributor.delete_role(podcast_id, "owner")
    map["owner"] && PodcastContributor.get_or_insert(map["owner"], "owner", podcast_id)

    map["author"] && Author.get_or_insert_persona_and_engagement(map["author"], podcast_id)

    PodcastContributor.delete_role(podcast_id, "managing_editor")
    map["managing_editor"] &&
      PodcastContributor.get_or_insert(map["managing_editor"], "managing editor", podcast_id)

    {:ok, feed} = Feed.get_by_podcast_id(podcast_id)
    if feed.self_link_url != feed_map[:self_link_url] do
      Feed.update_with_redirect_target(feed.id, feed_map[:self_link_url])
    end

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.delete_for_podcast(podcast_id)
    Language.persist_many(map[:languages], podcast)

    PodcastContributor.delete_role(podcast_id, "contributor")
    Contributor.persist_many(map[:contributors], podcast)

    map[:episodes] && Episode.update_from_feed_many(map[:episodes], podcast)

    podcast
    |> PanWeb.Podcast.changeset()
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
