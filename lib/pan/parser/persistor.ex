defmodule Pan.Parser.Persistor do
  alias Pan.Repo
  alias PanWeb.Image
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

  # podcast_id: nil for the first page of a feed, the podcast of the first
  # page for the following ones; feed_urls: the URLs the feed was fetched
  # from, see Pan.Parser.Podcast.get_or_insert/3. Returns {:ok, podcast_id},
  # or {:error, {:known_feed, podcast_id}} for a feed that is already known.
  def initial_import(map, podcast_id, feed_urls) do
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

    with {:ok, podcast} <- Podcast.get_or_insert(podcast_map, podcast_id, feed_urls) do
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

      {:ok, podcast.id}
    end
  end

  def delta_import(map, podcast) do
    map = Map.put_new(map, :last_build_date, now())

    if map.last_build_date != podcast.last_build_date do
      if map[:episodes] do
        Episode.persist_many(map.episodes, podcast)
        # new episodes bring new gigs, i.e. new episode_ids in persona docs
        Pan.Search.Persona.reset(Pan.Search.Persona.ids_for_podcast(podcast.id))
      end

      Feed.update_with_redirect_target(podcast.id, map[:new_feed_url])

      PanWeb.Podcast.changeset(podcast, %{last_build_date: map.last_build_date})
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    else
      {:ok, :nothing_to_do}
    end
  end

  def update_from_feed(map, podcast, opts \\ []) do
    Phoenix.PubSub.broadcast(:pan_pubsub, "podcasts:#{podcast.id}", %{
      content: "Updating from feed"
    })

    image_url = map[:image_url] || get_in(map, [:image, :image_url])
    image_title = map[:image_title] || get_in(map, [:image, :image_title]) || image_url

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
      |> maybe_put_image(image_url, image_title)

    feed_map = Map.drop(map[:feed], [:alternate_feeds])
    alternate_feeds_map = map[:feed][:alternate_feeds]

    episode_podcast_data = Pan.Search.Episode.podcast_data(podcast.id)
    persona_ids = Pan.Search.Persona.ids_for_podcast(podcast.id)
    {:ok, feed} = Feed.get_by_podcast_id(podcast.id)
    shared_feed = PanWeb.Feed.other_feed_with_same_url(feed)

    with :ok <- check_title_takeover(podcast, podcast_map[:title], shared_feed),
         {:ok, podcast} <- PanWeb.Podcast.changeset(podcast, podcast_map) |> Repo.update() do
      result =
        continue_update_from_feed(podcast, map, feed_map, alternate_feeds_map, image_url, opts)

      if Pan.Search.Episode.podcast_data(podcast.id) != episode_podcast_data do
        Pan.Search.Episode.reset_for_podcast(podcast.id)
      end

      # personas before and after: gigs/engagements may have been added or
      # dropped, and the podcast title in their docs may have changed
      Pan.Search.Persona.reset(persona_ids ++ Pan.Search.Persona.ids_for_podcast(podcast.id))

      result
    else
      # e.g. a feed without a title — don't let one bad metadata refresh
      # crash the whole job, report it and move on.
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, "Podcast #{podcast.id} update rejected: #{format_changeset_errors(changeset)}"}

      {:error, message} ->
        {:error, message}
    end
  end

  # With a feed shared with another podcast, a new title is most likely the
  # other podcast's, e.g. an old feed redirected to its successor ("Holding
  # Court" -> "Sixers Talk"); taking it over would turn this podcast into a
  # copy of the other one.
  defp check_title_takeover(_podcast, _title, nil), do: :ok
  defp check_title_takeover(_podcast, nil, _shared_feed), do: :ok
  defp check_title_takeover(%{title: title}, title, _shared_feed), do: :ok

  defp check_title_takeover(podcast, title, shared_feed) do
    {:error,
     "Podcast #{podcast.id} update rejected: its feed also belongs to podcast " <>
       "#{shared_feed.podcast_id}, the title #{inspect(title)} is not taken over"}
  end

  defp continue_update_from_feed(podcast, map, feed_map, alternate_feeds_map, image_url, opts) do
    if image_url, do: update_thumbnail(podcast)

    PodcastContributor.delete_role(podcast.id, "owner")
    map["owner"] && PodcastContributor.get_or_insert(map["owner"], "owner", podcast.id)

    map["author"] && Author.get_or_insert_persona_and_engagement(map["author"], podcast.id)

    PodcastContributor.delete_role(podcast.id, "managing_editor")

    map["managing_editor"] &&
      PodcastContributor.get_or_insert(map["managing_editor"], "managing editor", podcast.id)

    {:ok, feed} = Feed.get_by_podcast_id(podcast.id)

    # A differing <atom:link rel="self"> is only recorded, not followed: the
    # stored URL was just fetched successfully, and self links are often
    # stale or plain wrong (Zeit für Wissenschaft's mp3 feed points to its
    # ogg sibling over http, which 301s back to https). Moves are signalled
    # by HTTP redirects and <itunes:new-feed-url>.
    if feed_map[:self_link_url] && feed.self_link_url != feed_map[:self_link_url] do
      AlternateFeed.get_or_insert(feed.id, %{
        url: feed_map[:self_link_url],
        title: feed_map[:self_link_url]
      })
    end

    # <itunes:new-feed-url> is left to the episode updater, which first checks
    # that the announced feed is the same show (Pan.Updater.Succession).

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.delete_for_podcast(podcast.id)
    Language.persist_many(map[:languages], podcast)

    PodcastContributor.delete_stale_feed_derived(podcast.id)
    Contributor.persist_many(map[:contributors], podcast)

    maybe_update_episodes(map, podcast, opts)

    # full_text: false lets Pan.Job.PushMissingSearchIndex re-push the
    # refreshed title, thumbnail, categories, ... to Manticore
    PanWeb.Podcast.changeset(podcast, %{full_text: false})
    |> PanWeb.Podcast.update_counters()
    |> Repo.update()

    {:ok, :podcast_updated}
  end

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&PanWeb.CoreComponents.translate_error/1)
    |> Enum.map_join("; ", fn {field, messages} -> "#{field}: #{Enum.join(messages, ", ")}" end)
  end

  # opts[:skip_episodes] leaves episodes untouched entirely — used by the
  # unattended monthly metadata job, since update_from_feed_many/2 deletes
  # any episode no longer present in the feed, which cascades (DB-level
  # ON DELETE CASCADE) into deleting that episode's user likes/comments too.
  # See Pan.Parser.Podcast.update_from_feed/2 for the full rationale.
  defp maybe_update_episodes(map, podcast, opts) do
    if Keyword.get(opts, :skip_episodes, false) do
      :skipped
    else
      map[:episodes] && Episode.update_from_feed_many(map[:episodes], podcast)
    end
  end

  defp maybe_put_image(podcast_map, nil, _image_title), do: podcast_map

  defp maybe_put_image(podcast_map, image_url, image_title) do
    Map.merge(podcast_map, %{image_url: image_url, image_title: image_title})
  end

  defp update_thumbnail(podcast) do
    if old_image = Image.get_by_podcast_id(podcast.id) do
      Image.delete_asset(old_image)
    end

    PanWeb.Podcast.cache_thumbnail_image(podcast)

    PanWeb.Podcast.changeset(podcast, %{thumbnailed: true})
    |> Repo.update()
  end

  def contributor_import(map, podcast_id) do
    podcast = Repo.get!(PanWeb.Podcast, podcast_id)

    if map[:episodes] do
      Episode.insert_contributors(map[:episodes], podcast)
    end
  end
end
