defmodule PanWeb.PodcastMerge do
  @moduledoc """
  Merges podcast B into podcast A, e.g. a double import or the ogg feed of a
  show imported next to its mp3 feed (see PanWeb.PodcastDuplicates).

  - B's feed URL and its alternate feeds become alternate feeds of A, so a
    later import of B's URL is refused as already known.
  - An episode of B whose GUID A has too (format feeds share GUIDs) only
    hands over its enclosures, likes and recommendations, then it is
    deleted; A keeps its own chapters and gigs. Other episodes move to A.
  - Subscriptions, follows, likes, categories, languages, curations and
    engagements move, without creating duplicates; recommendations move.
  - A keeps its metadata; it takes over B's owner if it has none, and
    podcasts owned by different users are not merged.
  - If only B is in a community, it isn't merged into A (the community's
    API clients would lose B's id); merge A into B instead.
  - B's id is recorded as a PanWeb.FormerPodcast pointing to A.

  The DB foreign keys don't cascade, so every reference is handled here.
  """

  import Ecto.Query
  alias Pan.Repo
  alias Pan.Search
  alias PanWeb.{AlternateFeed, Community, Feed, FormerPodcast, Podcast}

  def merge(id, id), do: {:error, "A podcast can't be merged into itself."}

  def merge(from_id, to_id) do
    from_podcast = Repo.get!(Podcast, from_id)
    to_podcast = Repo.get!(Podcast, to_id)

    from_communities = Community.titles_for_podcast(from_id)

    cond do
      from_podcast.user_id && to_podcast.user_id && from_podcast.user_id != to_podcast.user_id ->
        {:error, "Both podcasts are owned by different users, not merged."}

      from_communities != [] and Community.titles_for_podcast(to_id) == [] ->
        {:error,
         "Podcast #{from_id} is in the community #{Enum.join(from_communities, ", ")}, " <>
           "#{to_id} is not: merge #{to_id} into #{from_id} instead, so the community keeps its ID."}

      true ->
        {:ok, {deleted_episode_ids, moved_episode_ids}} =
          Repo.transaction(fn -> merge_in_transaction(from_podcast, to_podcast) end,
            timeout: :infinity
          )

        Search.Podcast.delete_index(from_podcast.id)
        Search.Episode.delete_indices(deleted_episode_ids)
        Search.Episode.reset(moved_episode_ids)
        # re-pushed by Pan.Job.PushMissingSearchIndex
        from(p in Podcast, where: p.id == ^to_podcast.id)
        |> Repo.update_all(set: [full_text: false])

        Search.Persona.reset(Search.Persona.ids_for_podcast(to_podcast.id))

        {:ok,
         "Podcast #{from_podcast.id} \"#{from_podcast.title}\" merged into #{to_podcast.id} " <>
           "\"#{to_podcast.title}\": #{length(moved_episode_ids)} episodes moved, " <>
           "#{length(deleted_episode_ids)} merged into existing ones."}
    end
  end

  defp merge_in_transaction(from_podcast, to_podcast) do
    from_id = from_podcast.id
    to_id = to_podcast.id

    # before move_feeds, which takes B's feed away
    FormerPodcast.record(from_podcast, to_id)
    move_feeds(from_id, to_id)
    deleted_episode_ids = merge_shared_episodes(from_id, to_id)

    moved_episode_ids =
      from(e in PanWeb.Episode, where: e.podcast_id == ^from_id, select: e.id)
      |> Repo.update_all(set: [podcast_id: to_id])
      |> elem(1)

    move_unique("subscriptions", "user_id", from_id, to_id)
    move_unique("follows", "follower_id", from_id, to_id)
    move_unique("likes", "enjoyer_id", from_id, to_id)
    move_unique("categories_podcasts", "category_id", from_id, to_id)
    move_unique("languages_podcasts", "language_id", from_id, to_id)
    move_curations(from_id, to_id)
    move_engagements(from_id, to_id)
    sql("UPDATE recommendations SET podcast_id = $2 WHERE podcast_id = $1", [from_id, to_id])
    sql("DELETE FROM images WHERE podcast_id = $1", [from_id])

    if is_nil(to_podcast.user_id) and from_podcast.user_id do
      sql("UPDATE podcasts SET user_id = $2 WHERE id = $1", [to_id, from_podcast.user_id])
    end

    Repo.delete!(from_podcast)
    Podcast.clear_lonely_namesake(from_podcast.title)

    Repo.get!(Podcast, to_id)
    |> Podcast.changeset()
    |> Podcast.update_counters()
    |> Repo.update!()

    {deleted_episode_ids, moved_episode_ids}
  end

  defp move_feeds(from_id, to_id) do
    from_feeds =
      from(f in Feed, where: f.podcast_id == ^from_id, preload: :alternate_feeds) |> Repo.all()

    case Repo.one(from(f in Feed, where: f.podcast_id == ^to_id, order_by: f.id, limit: 1)) do
      # A without a feed of its own simply takes over B's
      nil ->
        from(f in Feed, where: f.podcast_id == ^from_id)
        |> Repo.update_all(set: [podcast_id: to_id])

      to_feed ->
        urls =
          Enum.flat_map(from_feeds, fn feed ->
            [feed.self_link_url | Enum.map(feed.alternate_feeds, & &1.url)]
          end)

        for url <- Enum.uniq(urls) do
          Pan.Parser.AlternateFeed.get_or_insert(to_feed.id, %{url: url, title: url})
        end

        from_feed_ids = Enum.map(from_feeds, & &1.id)
        from(a in AlternateFeed, where: a.feed_id in ^from_feed_ids) |> Repo.delete_all()
        from(f in Feed, where: f.id in ^from_feed_ids) |> Repo.delete_all()
    end
  end

  # Episodes of B with a GUID A has too: hand over what A's copy doesn't have
  # yet, then delete B's copy. Returns the deleted episode ids.
  defp merge_shared_episodes(from_id, to_id) do
    pairs = """
    WITH pairs AS (
      SELECT b.id AS b_id, a.id AS a_id
      FROM episodes b JOIN episodes a ON a.guid = b.guid AND a.podcast_id = $2
      WHERE b.podcast_id = $1
    )
    """

    params = [from_id, to_id]

    sql(
      pairs <>
        """
        UPDATE enclosures e SET episode_id = p.a_id FROM pairs p
        WHERE e.episode_id = p.b_id
          AND NOT EXISTS (SELECT 1 FROM enclosures x WHERE x.episode_id = p.a_id AND x.url = e.url)
        """,
      params
    )

    sql(
      pairs <>
        """
        DELETE FROM likes l USING pairs p
        WHERE l.episode_id = p.b_id
          AND EXISTS (SELECT 1 FROM likes x WHERE x.episode_id = p.a_id AND x.enjoyer_id = l.enjoyer_id)
        """,
      params
    )

    sql(
      pairs <> "UPDATE likes l SET episode_id = p.a_id FROM pairs p WHERE l.episode_id = p.b_id",
      params
    )

    sql(
      pairs <>
        "UPDATE recommendations r SET episode_id = p.a_id FROM pairs p WHERE r.episode_id = p.b_id",
      params
    )

    sql(
      pairs <>
        """
        DELETE FROM likes l USING chapters c, pairs p
        WHERE l.chapter_id = c.id AND c.episode_id = p.b_id
        """,
      params
    )

    for table <- ["chapters", "gigs", "enclosures"] do
      sql(pairs <> "DELETE FROM #{table} t USING pairs p WHERE t.episode_id = p.b_id", params)
    end

    %{rows: rows} =
      sql(
        pairs <> "DELETE FROM episodes e USING pairs p WHERE e.id = p.b_id RETURNING e.id",
        params
      )

    List.flatten(rows)
  end

  # Moves B's rows of a table to A, dropping those A already has for the same
  # user/category/language (`key`). For likes and follows only podcast-level
  # rows count, not those for a category, persona etc. of the same row.
  defp move_unique(table, key, from_id, to_id) do
    sql(
      """
      DELETE FROM #{table} t
      WHERE t.podcast_id = $1
        AND EXISTS (SELECT 1 FROM #{table} x WHERE x.podcast_id = $2 AND x.#{key} = t.#{key})
      """,
      [from_id, to_id]
    )

    sql("UPDATE #{table} SET podcast_id = $2 WHERE podcast_id = $1", [from_id, to_id])
  end

  defp move_curations(from_id, to_id) do
    sql(
      """
      DELETE FROM curations t
      WHERE t.podcast_id = $1
        AND EXISTS (SELECT 1 FROM curations x
                    WHERE x.podcast_id = $2 AND x.user_id = t.user_id AND x.community_id = t.community_id)
      """,
      [from_id, to_id]
    )

    sql("UPDATE curations SET podcast_id = $2 WHERE podcast_id = $1", [from_id, to_id])
  end

  defp move_engagements(from_id, to_id) do
    sql(
      """
      DELETE FROM engagements t
      WHERE t.podcast_id = $1
        AND EXISTS (SELECT 1 FROM engagements x
                    WHERE x.podcast_id = $2 AND x.persona_id = t.persona_id AND x.role = t.role)
      """,
      [from_id, to_id]
    )

    sql("UPDATE engagements SET podcast_id = $2 WHERE podcast_id = $1", [from_id, to_id])
  end

  defp sql(query, params), do: Repo.query!(query, params, timeout: :infinity)
end
