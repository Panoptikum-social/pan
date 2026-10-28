defmodule PanWeb.Feed do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{AlternateFeed, Category, Feed, Podcast}

  schema "feeds" do
    field(:self_link_title, :string)
    field(:self_link_url, :string)
    field(:next_page_url, :string)
    field(:prev_page_url, :string)
    field(:first_page_url, :string)
    field(:last_page_url, :string)
    field(:hub_link_url, :string)
    field(:feed_generator, :string)
    field(:etag, :string)
    field(:last_modified, :naive_datetime)
    field(:trust_last_modified, :boolean, default: false)
    field(:no_headers_available, :boolean, default: false)
    field(:hash, :string)
    timestamps()

    belongs_to(:podcast, Podcast)
    has_many(:alternate_feeds, AlternateFeed, on_delete: :delete_all)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :self_link_url,
      :self_link_title,
      :next_page_url,
      :prev_page_url,
      :etag,
      :first_page_url,
      :last_page_url,
      :hub_link_url,
      :feed_generator,
      :podcast_id,
      :last_modified,
      :trust_last_modified,
      :no_headers_available,
      :hash
    ])
    |> validate_required([:self_link_url])
    |> cast_assoc(:alternate_feeds)
  end

  # A hint for admins (feed backlog): falls back to ever shorter prefixes of
  # the url, so on shared hosts it can return an unrelated podcast's feed,
  # e.g. "anchor.fm/s/528cb318/podcast/rss" ends up matching "anchor.fm/s".
  def clean_and_best_matching(url), do: url |> clean() |> best_matching()

  # For code that acts on the match without a human looking at it (moderators
  # adding a feed): only a feed known by this url, as alternate feed or website.
  def clean_and_direct_matching(url), do: url |> clean() |> direct_matching()

  defp clean(url) do
    url
    |> String.split("/", parts: 3)
    |> List.last()
    |> String.replace("feeds.feedburner.com/", "")
  end

  def best_matching(url) do
    cond do
      feed = direct_matching(url) ->
        feed

      String.contains?(url, "/") ->
        url
        |> String.reverse()
        |> String.split("/", parts: 2)
        |> List.last()
        |> String.reverse()
        |> best_matching

      true ->
        nil
    end
  end

  defp direct_matching(url) do
    # Anchored on a preceding "/" (every real URL has one right before any
    # host or path fragment, via "scheme://" at minimum) so a shorter host
    # that's a suffix of a longer one — "aufdistanz.de" vs.
    # "horizons.aufdistanz.de" — can't false-match. An unanchored "%url%"
    # would match both, and with no ORDER BY + limit: 1, silently pick
    # whichever one happens to come back first.
    anchored = "%/#{url}%"

    cond do
      feed =
          from(f in Feed,
            where: ilike(f.self_link_url, ^anchored),
            limit: 1
          )
          |> Repo.one() ->
        feed

      alternate_feed =
          from(a in AlternateFeed,
            where: ilike(a.url, ^anchored),
            preload: :feed,
            limit: 1
          )
          |> Repo.one() ->
        alternate_feed.feed

      podcast =
          from(p in Podcast,
            where: ilike(p.website, ^anchored),
            preload: :feeds,
            limit: 1
          )
          |> Repo.one() ->
        List.first(podcast.feeds)

      true ->
        nil
    end
  end

  # For the first import, which decides on its own whether a feed is already
  # known: only an exact match of one of `urls` (http and https count as the
  # same) with a feed URL or an alternate feed URL. Unlike direct_matching/1
  # no substring and no website match, a wrong match would merge two podcasts.
  def exact_matching(urls) do
    bare_urls = Enum.map(urls, &(&1 |> String.trim() |> String.replace(~r/^https?:\/\//i, "")))

    from(f in Feed,
      where:
        fragment("regexp_replace(trim(?), '^https\\?://', '', 'i')", f.self_link_url) in ^bare_urls,
      order_by: f.id,
      limit: 1
    )
    |> Repo.one() ||
      from(a in AlternateFeed,
        join: f in assoc(a, :feed),
        where: fragment("regexp_replace(trim(?), '^https\\?://', '', 'i')", a.url) in ^bare_urls,
        order_by: f.id,
        select: f,
        limit: 1
      )
      |> Repo.one()
  end

  # Another podcast's feed with the same URL (http and https count as the
  # same): a double import, or a podcast whose feed was redirected to its
  # successor's ("Holding Court" -> "Sixers Talk").
  def other_feed_with_same_url(%Feed{id: id, self_link_url: url}) do
    bare_url = url |> String.trim() |> String.replace(~r/^https?:\/\//i, "")

    from(f in Feed,
      where:
        f.id != ^id and
          fragment("regexp_replace(trim(?), '^https\\?://', '', 'i')", f.self_link_url) ==
            ^bare_url,
      order_by: f.id,
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Makes one of the feed's alternate feed URLs (e.g. the URL before a
  redirect to an error page) the feed URL again, see change_url/2.
  """
  def restore_alternate(%Feed{} = feed, url) do
    if Repo.exists?(from(a in AlternateFeed, where: a.feed_id == ^feed.id and a.url == ^url)) do
      change_url(feed, url)
    else
      {:error, "#{url} is not an alternate feed of feed #{feed.id}"}
    end
  end

  @doc """
  Gives the feed a new URL; the current one (`feed` as loaded before any
  change) is kept as an alternate feed. The stored hash and headers belonged
  to the old URL, and the podcast is due right away, so the next update shows
  whether the new one works.
  """
  def change_url(%Feed{} = feed, url) do
    Pan.Parser.AlternateFeed.get_or_insert(feed.id, %{
      url: feed.self_link_url,
      title: feed.self_link_url
    })

    from(p in Podcast, where: p.id == ^feed.podcast_id)
    |> Repo.update_all(set: [next_update: Pan.Parser.MyDateTime.now()])

    feed
    |> Feed.changeset(%{
      self_link_url: url,
      hash: nil,
      etag: nil,
      last_modified: nil,
      trust_last_modified: false,
      no_headers_available: false
    })
    |> Repo.update()
  end

  @doc "All feed URLs, as `[[url]]`, for exporting them from the console."
  def feed_urls do
    Repo.all(from(f in Feed, select: [f.self_link_url]))
  end

  def get_by_id(id) do
    Repo.get!(Feed, id)
  end

  def ids_by_category_id_and_podcast_id(category_id, podcast_id) do
    from(c in Category,
      join: p in assoc(c, :podcasts),
      join: f in assoc(p, :feeds),
      where:
        c.id == ^category_id and (not p.blocked or is_nil(p.blocked)) and p.id == ^podcast_id,
      select: f.id
    )
    |> Repo.all()
  end
end
