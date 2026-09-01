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

    case PanWeb.Podcast.changeset(podcast, podcast_map) |> Repo.update() do
      {:ok, podcast} ->
        continue_update_from_feed(podcast, map, feed_map, alternate_feeds_map, image_url, opts)

      {:error, changeset} ->
        # e.g. a feed that started serving something else entirely (a
        # WordPress comments feed, say) can hand us a title that collides
        # with another podcast's — don't let one bad metadata refresh crash
        # the whole job, report it and move on.
        {:error, "Podcast #{podcast.id} update rejected: #{format_changeset_errors(changeset)}"}
    end
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

    if feed.self_link_url != feed_map[:self_link_url] do
      Feed.update_with_redirect_target(podcast.id, feed_map[:self_link_url])
    end

    # Applied last so it wins over the self_link_url check above: the feed's
    # own explicit "I've moved" signal is more authoritative than us noticing
    # its <atom:link rel="self"> doesn't match what we had stored.
    Feed.update_with_redirect_target(podcast.id, map[:new_feed_url])

    Category.persist_many(map[:categories], podcast)
    AlternateFeed.get_or_insert_many(alternate_feeds_map, feed.id)

    Language.delete_for_podcast(podcast.id)
    Language.persist_many(map[:languages], podcast)

    PodcastContributor.delete_stale_feed_derived(podcast.id)
    Contributor.persist_many(map[:contributors], podcast)

    maybe_update_episodes(map, podcast, opts)

    PanWeb.Podcast.changeset(podcast)
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
