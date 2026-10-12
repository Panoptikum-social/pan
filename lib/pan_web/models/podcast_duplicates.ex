defmodule PanWeb.PodcastDuplicates do
  @moduledoc """
  Candidates for the admin duplicates page. Since 2026-10-12 a podcast is
  identified by its feed URL only ("if in doubt, import twice"), so double
  imports and format feeds (mp3/ogg of one show) end up as separate podcasts
  and are merged by hand. Each check is a separate list, so the admin sees
  why two podcasts are listed.
  """

  import Ecto.Query
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Feed, Podcast}

  @bare_url "regexp_replace(trim(?), '^https\\?://', '', 'i')"

  @doc "Groups of podcasts whose feeds have the same URL (http/https alike)."
  def same_feed_url do
    from(f in Feed,
      group_by: fragment(@bare_url, f.self_link_url),
      having: count(f.id) > 1,
      select:
        {fragment(@bare_url, f.self_link_url),
         fragment("array_agg(? order by ?)", f.podcast_id, f.podcast_id)},
      order_by: fragment(@bare_url, f.self_link_url)
    )
    |> Repo.all()
    |> with_podcasts()
  end

  @doc """
  Pairs where one podcast's feed URL is an alternate feed (e.g. an old URL
  before a redirect) of another podcast.
  """
  def feed_url_is_alternate do
    from(f in Feed,
      join: a in assoc(f, :alternate_feeds),
      join: other in Feed,
      on: fragment(@bare_url, a.url) == fragment(@bare_url, other.self_link_url),
      where: other.podcast_id != f.podcast_id,
      distinct: true,
      select: {other.self_link_url, [f.podcast_id, other.podcast_id]},
      order_by: [f.podcast_id, other.podcast_id]
    )
    |> Repo.all()
    |> with_podcasts()
  end

  @doc "Groups of podcasts with the same title (case and surrounding spaces ignored)."
  def same_title do
    from(p in Podcast,
      group_by: fragment("lower(trim(?))", p.title),
      having: count(p.id) > 1,
      select: {min(p.title), fragment("array_agg(? order by ?)", p.id, p.id)},
      order_by: fragment("lower(trim(?))", p.title)
    )
    |> Repo.all()
    |> with_podcasts()
  end

  @doc """
  Podcasts whose feed now delivers a different show or needs a review,
  marked by Pan.Updater.Succession in last_error_message.
  """
  def marked_by_updater do
    from(p in Podcast,
      where: like(p.last_error_message, "Feed now delivers%"),
      order_by: [desc: p.last_error_occured],
      preload: ^[feeds: [alternate_feeds: newest_first()]]
    )
    |> Repo.all()
  end

  # the previous URLs offered for a restore
  defp newest_first, do: from(a in AlternateFeed, order_by: [desc: a.inserted_at])

  # [{key, [podcast_id]}] -> [{key, [%Podcast{}]}], with one query for all
  defp with_podcasts(groups) do
    ids = groups |> Enum.flat_map(&elem(&1, 1)) |> Enum.uniq()

    podcasts =
      from(p in Podcast,
        where: p.id in ^ids,
        preload: ^[feeds: [alternate_feeds: newest_first()]]
      )
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    for {key, group_ids} <- groups,
        do: {key, group_ids |> Enum.map(&podcasts[&1]) |> Enum.reject(&is_nil/1)}
  end
end
