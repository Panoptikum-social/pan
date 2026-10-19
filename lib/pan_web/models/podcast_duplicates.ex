defmodule PanWeb.PodcastDuplicates do
  @moduledoc """
  Candidates for the admin duplicates page. Since 2026-10-12 a podcast is
  identified by its feed URL only ("if in doubt, import twice"), so double
  imports and format feeds (mp3/ogg of one show) end up as separate podcasts
  and are merged by hand. Each check is a separate list, so the admin sees
  why two podcasts are listed.
  """

  import Ecto.Query
  alias Pan.Parser.Download
  alias Pan.Repo
  alias Pan.Updater.RssFeed
  alias PanWeb.{AlternateFeed, Feed, Podcast}

  @bare_url "regexp_replace(trim(?), '^https\\?://', '', 'i')"

  @doc """
  The number of entries per check, as on the tabs of the duplicates page,
  without loading the podcasts.
  """
  def counts do
    %{
      different_show: Repo.aggregate(marked_by_updater_query(), :count),
      same_feed_url: count_rows(same_feed_url_query()),
      same_title: count_rows(same_title_query()),
      alternate: count_rows(feed_url_is_alternate_query())
    }
  end

  # in SQL, as an Ecto subquery can't select the tuples these queries return
  defp count_rows(query) do
    {sql, params} = Repo.to_sql(:all, query)
    [[count]] = Repo.query!("SELECT count(*) FROM (#{sql}) AS rows", params).rows
    count
  end

  @doc "Groups of podcasts whose feeds have the same URL (http/https alike)."
  def same_feed_url do
    same_feed_url_query()
    |> order_by([f], fragment(@bare_url, f.self_link_url))
    |> Repo.all()
    |> with_podcasts()
  end

  defp same_feed_url_query do
    from(f in Feed,
      group_by: fragment(@bare_url, f.self_link_url),
      having: count(f.id) > 1,
      select:
        {fragment(@bare_url, f.self_link_url),
         fragment("array_agg(? order by ?)", f.podcast_id, f.podcast_id)}
    )
  end

  @doc """
  Pairs where one podcast's feed URL is an alternate feed (e.g. an old URL
  before a redirect) of another podcast.
  """
  def feed_url_is_alternate(counted \\ :all) do
    feed_url_is_alternate_query()
    |> order_by([f, _a, other], [f.podcast_id, other.podcast_id])
    |> Repo.all()
    |> with_podcasts()
    |> with_shared_episode_titles(counted)
  end

  defp feed_url_is_alternate_query do
    from(f in Feed,
      join: a in assoc(f, :alternate_feeds),
      join: other in Feed,
      on: fragment(@bare_url, a.url) == fragment(@bare_url, other.self_link_url),
      where: other.podcast_id != f.podcast_id,
      distinct: true,
      select: {other.self_link_url, [f.podcast_id, other.podcast_id]}
    )
  end

  @doc """
  Groups of podcasts with the same title (case and surrounding spaces
  ignored) that aren't all marked as namesakes, as
  `{title, podcasts, shared_episode_titles}`. For a pair, the
  number of episode titles both have tells the same show twice from two
  shows that just share a title; nil for bigger groups.
  """
  def same_title do
    same_title_query()
    |> order_by([p], fragment("lower(trim(?))", p.title))
    |> Repo.all()
    |> with_podcasts()
    |> with_shared_episode_titles(:all)
  end

  defp same_title_query do
    from(p in Podcast,
      group_by: fragment("lower(trim(?))", p.title),
      # groups an admin marked as namesakes (different shows) are done, unless
      # another podcast with the title came along since
      having: count(p.id) > 1 and fragment("not bool_and(?)", p.namesake),
      select: {min(p.title), fragment("array_agg(? order by ?)", p.id, p.id)}
    )
  end

  # [{key, podcasts}] -> [{key, podcasts, shared}], shared being the number
  # of episode titles both podcasts of a pair have (nil for bigger groups and
  # beyond the first `counted` entries). One query for all pairs, still slow
  # for thousands of them (17 s for all alternate feed pairs), hence `counted`.
  defp with_shared_episode_titles(groups, counted) do
    {to_count, rest} = if counted == :all, do: {groups, []}, else: Enum.split(groups, counted)
    pairs = for {_key, [a, b]} <- to_count, uniq: true, do: {a.id, b.id}
    shared = shared_episode_titles(pairs)

    Enum.map(to_count, fn
      {key, [a, b] = podcasts} -> {key, podcasts, shared[{a.id, b.id}]}
      {key, podcasts} -> {key, podcasts, nil}
    end) ++ Enum.map(rest, fn {key, podcasts} -> {key, podcasts, nil} end)
  end

  defp shared_episode_titles([]), do: %{}

  defp shared_episode_titles(pairs) do
    {as, bs} = Enum.unzip(pairs)

    Repo.query!(
      """
      SELECT p.a, p.b,
        (SELECT count(DISTINCT x.title) FROM episodes x
         JOIN episodes y ON y.title = x.title AND y.podcast_id = p.b
         WHERE x.podcast_id = p.a)
      FROM unnest($1::bigint[], $2::bigint[]) AS p(a, b)
      """,
      [as, bs],
      timeout: :infinity
    ).rows
    |> Map.new(fn [a, b, count] -> {{a, b}, count} end)
  end

  @doc """
  Podcasts whose feed now delivers a different show or needs a review,
  marked by Pan.Updater.Succession in last_error_message.
  """
  def marked_by_updater do
    from(p in marked_by_updater_query(),
      order_by: [desc: p.last_error_occured],
      preload: ^[feeds: [alternate_feeds: newest_first()]]
    )
    |> Repo.all()
  end

  defp marked_by_updater_query,
    do: from(p in Podcast, where: like(p.last_error_message, "Feed now delivers%"))

  @doc """
  The channel title the feed at `url` delivers right now, or a short note if
  it delivers no feed. One request, on demand from the duplicates page:
  podcasts sharing a feed keep their own titles (the metadata refresh doesn't
  take over a new one), so this shows what the feed actually says.
  """
  def current_feed_title(url) do
    case Download.get(url, follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        if String.contains?(body, "<rss"),
          do: elem(RssFeed.titles(body), 0) || "(feed without a title)",
          else: "(no feed: not RSS)"

      {:ok, %HTTPoison.Response{status_code: code}} ->
        "(no feed: HTTP #{code})"

      {:error, reason} ->
        "(no feed: #{inspect(reason)})"
    end
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
