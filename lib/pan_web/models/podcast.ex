defmodule PanWeb.Podcast do
  use PanWeb, :model
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2, time_diff: 3]
  alias Pan.Parser.Helpers
  alias Pan.{Repo, Search}
  require Logger

  alias PanWeb.{
    Category,
    Community,
    Engagement,
    Episode,
    Feed,
    Follow,
    Gig,
    Image,
    Language,
    Like,
    Persona,
    Podcast,
    Recommendation,
    Subscription,
    User
  }

  schema "podcasts" do
    field(:title, :string)
    field(:website, :string)
    field(:description, Ecto.EctoText)
    field(:summary, Ecto.EctoText)
    field(:image_title, :string)
    field(:image_url, :string)
    field(:last_build_date, :naive_datetime)
    field(:payment_link_title, :string)
    field(:payment_link_url, :string)
    field(:explicit, :boolean, default: false)
    field(:blocked, :boolean, default: false)
    field(:update_paused, :boolean, default: false)
    field(:update_intervall, :integer)
    field(:next_update, :naive_datetime)
    field(:next_podcast_update, :naive_datetime)
    field(:retired, :boolean, default: false)
    field(:failure_count, :integer)
    field(:unique_identifier, Ecto.UUID)
    field(:episodes_count, :integer)
    field(:followers_count, :integer)
    field(:likes_count, :integer)
    field(:subscriptions_count, :integer)
    field(:latest_episode_publishing_date, :naive_datetime)
    field(:publication_frequency, :float)
    field(:manually_updated_at, :naive_datetime)
    field(:full_text, :boolean, default: false)
    field(:thumbnailed, :boolean, default: false)
    field(:last_error_message, :string)
    field(:last_error_occured, :naive_datetime)
    field(:status_code, :string, virtual: true)
    timestamps()

    has_many(:episodes, Episode, on_delete: :delete_all)
    has_many(:feeds, Feed, on_delete: :delete_all)
    has_many(:recommendations, Recommendation, on_delete: :delete_all)
    has_many(:engagements, Engagement, on_delete: :delete_all)
    has_many(:thumbnails, Image, on_delete: :delete_all)

    many_to_many(:categories, Category,
      join_through: "categories_podcasts",
      on_delete: :delete_all
    )

    many_to_many(:contributors, Persona, join_through: "engagements")

    many_to_many(:listeners, User,
      join_through: "subscriptions",
      on_delete: :delete_all
    )

    many_to_many(:likers, User,
      join_through: "likes",
      join_keys: [podcast_id: :id, enjoyer_id: :id],
      on_delete: :delete_all
    )

    many_to_many(:followers, User,
      join_through: "follows",
      join_keys: [podcast_id: :id, follower_id: :id],
      on_delete: :delete_all
    )

    many_to_many(:languages, Language,
      join_through: "languages_podcasts",
      on_delete: :delete_all
    )
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :title,
      :website,
      :last_build_date,
      :explicit,
      :payment_link_title,
      :payment_link_url,
      :unique_identifier,
      :image_title,
      :image_url,
      :description,
      :summary,
      :update_paused,
      :blocked,
      :retired,
      :updated_at,
      :update_intervall,
      :next_update,
      :next_podcast_update,
      :episodes_count,
      :followers_count,
      :likes_count,
      :subscriptions_count,
      :latest_episode_publishing_date,
      :publication_frequency,
      :failure_count,
      :manually_updated_at,
      :full_text,
      :thumbnailed,
      :last_error_message,
      :last_error_occured
    ])
    |> validate_required([:title, :update_intervall, :next_update])
    |> unique_constraint(:title)
  end

  def like(podcast_id, user_id) do
    response =
      case Like.find_podcast_like(user_id, podcast_id) do
        nil ->
          %Like{enjoyer_id: user_id, podcast_id: podcast_id}
          |> Repo.insert()

        like ->
          {:ok, Repo.delete!(like)}
      end

    Podcast.update_likes_count(podcast_id)
    response
  end

  def follow(podcast_id, user_id) do
    response =
      case Repo.get_by(Follow,
             follower_id: user_id,
             podcast_id: podcast_id
           ) do
        nil ->
          %Follow{follower_id: user_id, podcast_id: podcast_id}
          |> Repo.insert()

        follow ->
          {:ok, Repo.delete!(follow)}
      end

    Podcast.update_followers_count(podcast_id)
    response
  end

  def subscribe(podcast_id, user_id) do
    response =
      case Repo.get_by(Subscription,
             user_id: user_id,
             podcast_id: podcast_id
           ) do
        nil ->
          %Subscription{user_id: user_id, podcast_id: podcast_id}
          |> Repo.insert()

        subscription ->
          {:ok, Repo.delete!(subscription)}
      end

    Podcast.update_subscriptions_count(podcast_id)
    response
  end

  def follower_mailboxes(podcast_id) do
    Repo.all(
      from(l in Follow,
        where: l.podcast_id == ^podcast_id,
        select: [:follower_id]
      )
    )
    |> Enum.map(fn user -> "mailboxes:" <> Integer.to_string(user.follower_id) end)
  end

  def latest do
    first_engagement =
      from(e in Engagement,
        where: parent_as(:podcast).id == e.podcast_id,
        limit: 1,
        select: [:persona_id]
      )

    from(p in Podcast,
      as: :podcast,
      order_by: [fragment("? DESC NULLS LAST", p.inserted_at)],
      where: not p.blocked or is_nil(p.blocked),
      inner_lateral_join: e in subquery(first_engagement),
      on: true,
      join: persona in assoc(e, :persona),
      select: %{
        id: p.id,
        title: p.title,
        inserted_at: p.inserted_at,
        description: p.description,
        author_id: persona.id,
        author_name: persona.name
      },
      limit: 1
    )
    |> Repo.one()
  end

  def latest_for_index(page, per_page) do
    from(p in Podcast,
      order_by: [desc: :inserted_at],
      where: not p.blocked or is_nil(p.blocked),
      preload: [:categories, [engagements: :persona], :thumbnails],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def popular do
    from(p in Podcast,
      select: [p.subscriptions_count, p.id, p.title],
      order_by: [fragment("? DESC NULLS LAST", p.subscriptions_count)],
      limit: 10
    )
    |> Repo.all()
  end

  def liked do
    from(p in Podcast,
      select: [p.likes_count, p.id, p.title],
      order_by: [fragment("? DESC NULLS LAST", p.likes_count)],
      limit: 10
    )
    |> Repo.all()
  end

  def author(podcast) do
    engagement =
      from(Engagement,
        where: [role: "author", podcast_id: ^podcast.id],
        preload: :persona,
        limit: 1
      )
      |> Repo.all()
      |> List.first()

    if engagement, do: engagement.persona
  end

  def author_name(podcast) do
    author = author(podcast)
    if author, do: author.name
  end

  def get_one_stale do
    from(p in Podcast,
      where:
        p.next_update <= ^now() and
          not p.update_paused and not p.retired,
      order_by: [asc: :next_update],
      limit: 1
    )
    |> Repo.one()
  end

  def import_stale(nil) do
    # return 10 for next update in 10 seconds
    10
  end

  def import_stale(podcast) do
    Pan.Updater.Podcast.import_new_episodes(podcast)
    # return 0 for immediate next update
    0
  end

  @doc """
  Podcasts due for the monthly metadata-only refresh (see
  Pan.Job.RefreshPodcastMetadata). Same `not update_paused and not retired`
  guard as get_one_stale/0 above — a podcast an admin paused, or one already
  retired after 9 failed episode updates, is skipped here too.
  """
  def get_due_for_metadata_refresh(limit) do
    from(p in Podcast,
      where:
        p.next_podcast_update <= ^now() and
          not p.update_paused and not p.retired,
      order_by: [asc: :next_podcast_update],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Called after every metadata-refresh attempt, success or failure alike —
  there's no separate failure backoff here (unlike update_intervall for
  episodes): a persistently broken feed already gets caught by the episode
  job's failure-count/retire-after-9 mechanism, and retired podcasts are
  already excluded by get_due_for_metadata_refresh/1 above.

  A few days of random jitter keeps podcasts from reclumping onto the same
  day every month.
  """
  def reschedule_metadata_refresh(podcast) do
    podcast
    |> Podcast.changeset(%{next_podcast_update: next_metadata_refresh_date()})
    |> Repo.update()
  end

  @doc "28-32 days out, so newly-imported podcasts join the same monthly rotation."
  def next_metadata_refresh_date do
    time_shift(now(), days: 27 + :rand.uniform(5))
  end

  @doc """
  Records a failed monthly metadata refresh (Pan.Job.RefreshPodcastMetadata):
  bumps `failure_count` and persists `last_error_message`/
  `last_error_occured`, the same fields Pan.Updater.Podcast's episode-update
  path uses. Deliberately does *not* retire the podcast at any threshold,
  unlike that path's mechanism — a metadata-validation failure (e.g. a
  title collision) says nothing about whether the feed itself is alive,
  which is what retirement is meant to signal (see
  get_due_for_metadata_refresh/1's and reschedule_metadata_refresh/1's docs
  above).
  """
  def record_metadata_refresh_failure(podcast, message) do
    podcast
    |> Podcast.changeset(%{
      failure_count: (podcast.failure_count || 0) + 1,
      # last_error_message is varchar(255) — a crash's full formatted
      # message + stacktrace (Exception.format/3) regularly runs far past
      # that, and an uncaught length overflow here would crash the error
      # *recorder* itself, taking the whole job down a second time.
      last_error_message: Helpers.to_255(message),
      last_error_occured: now()
    })
    |> Repo.update(force: true)
  end

  def remove_unwanted_references(id) do
    podcast = Repo.get(Podcast, id)
    Search.Podcast.delete_index(id)

    if podcast.blocked do
      episode_ids =
        from(e in Episode,
          where: e.podcast_id == ^id,
          select: e.id
        )
        |> Repo.all()

      from(g in Gig, where: g.episode_id in ^episode_ids)
      |> Repo.delete_all()

      for episode_id <- episode_ids do
        Search.Episode.delete_index(episode_id)
      end

      from(e in Engagement, where: e.podcast_id == ^id)
      |> Repo.delete_all()

      from(cp in PanWeb.CategoryPodcast, where: cp.podcast_id == ^id)
      |> Repo.delete_all()

      from(f in PanWeb.Follow, where: f.podcast_id == ^id)
      |> Repo.delete_all()

      from(lp in "languages_podcasts", where: lp.podcast_id == ^id)
      |> Repo.delete_all()

      from(r in PanWeb.Recommendation, where: r.podcast_id == ^id)
      |> Repo.delete_all()

      from(r in PanWeb.Recommendation, where: r.episode_id in ^episode_ids)
      |> Repo.delete_all()

      chapter_ids =
        from(c in PanWeb.Chapter,
          where: c.episode_id in ^episode_ids,
          select: c.id
        )
        |> Repo.all()

      from(r in PanWeb.Recommendation, where: r.chapter_id in ^chapter_ids)
      |> Repo.delete_all()

      from(s in PanWeb.Subscription, where: s.podcast_id == ^id)
      |> Repo.delete_all()
    end
  end

  def derive_intervall(id) do
    last_update =
      from(e in Episode,
        where: e.podcast_id == ^id,
        order_by: [desc: :updated_at],
        limit: 1,
        select: e.updated_at
      )
      |> Repo.all()
      |> List.first()

    hours = time_diff(now(), last_update, :hours)

    # approximate solution for u_i*(u_i+1)/2 = hours
    update_intervall = round(:math.sqrt(8 * hours) / 2)
    next_update = time_shift(now(), hours: update_intervall)

    Repo.get(Podcast, id)
    |> Podcast.changeset(%{update_intervall: update_intervall, next_update: next_update})
    |> Repo.update()
  end

  def derive_all_intervalls() do
    podcast_ids =
      from(p in Podcast,
        where: is_nil(p.update_intervall),
        select: p.id
      )
      |> Repo.all()

    for podcast_id <- podcast_ids do
      derive_intervall(podcast_id)
    end
  end

  def update_counters(podcast_changeset) do
    podcast_id = podcast_changeset.data.id

    episodes_count =
      where(Episode, podcast_id: ^podcast_id)
      |> Repo.aggregate(:count)

    likes_count =
      where(Like, podcast_id: ^podcast_id)
      |> Repo.aggregate(:count)

    followers_count =
      where(Follow, podcast_id: ^podcast_id)
      |> Repo.aggregate(:count)

    subscriptions_count =
      where(Subscription, podcast_id: ^podcast_id)
      |> Repo.aggregate(:count)

    episode_publishing_dates =
      from(e in Episode,
        where: e.podcast_id == ^podcast_id,
        select: [e.publishing_date, e.inserted_at]
      )
      |> Repo.all()
      |> Enum.map(&best_effort_for_pubdate(&1))
      |> Enum.sort_by(&NaiveDateTime.to_erl/1)

    latest_episode_publishing_date = List.last(episode_publishing_dates)
    first_episode_publishing_date = List.first(episode_publishing_dates)

    publication_frequency =
      if episodes_count > 1 && latest_episode_publishing_date && first_episode_publishing_date do
        NaiveDateTime.diff(latest_episode_publishing_date, first_episode_publishing_date, :second) /
          (episodes_count - 1) / 86_400
      else
        0.0
      end

    podcast_changeset
    |> put_change(:episodes_count, episodes_count)
    |> put_change(:likes_count, likes_count)
    |> put_change(:followers_count, followers_count)
    |> put_change(:subscriptions_count, subscriptions_count)
    |> put_change(:latest_episode_publishing_date, latest_episode_publishing_date)
    |> put_change(:publication_frequency, publication_frequency)
  end

  def best_effort_for_pubdate([publishing_date, inserted_at]) do
    publishing_date || inserted_at
  end

  def update_all_counters do
    podcasts = Repo.all(Podcast)

    for podcast <- podcasts do
      Logger.info("Updating counter for podcast: #{podcast.id} #{podcast.title}")

      podcast
      |> PanWeb.Podcast.changeset()
      |> PanWeb.Podcast.update_counters()
      |> Repo.update()
    end
  end

  def update_likes_count(id) do
    likes_count =
      from(l in Like, where: l.podcast_id == ^id)
      |> Repo.aggregate(:count)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:likes_count, likes_count)
    |> Repo.update()
  end

  def update_followers_count(id) do
    followers_count =
      from(f in Follow, where: f.podcast_id == ^id)
      |> Repo.aggregate(:count)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:followers_count, followers_count)
    |> Repo.update()
  end

  def update_subscriptions_count(id) do
    subscriptions_count =
      from(s in Subscription, where: s.podcast_id == ^id)
      |> Repo.aggregate(:count)

    Repo.get!(Podcast, id)
    |> PanWeb.Podcast.changeset()
    |> put_change(:subscriptions_count, subscriptions_count)
    |> Repo.update()
  end

  def cache_missing_thumbnail_images() do
    podcast_ids =
      from(p in Podcast,
        where:
          not p.thumbnailed and
            not is_nil(p.image_url),
        limit: 250,
        select: p.id
      )
      |> Repo.all()

    podcasts =
      from(p in Podcast, where: p.id in ^podcast_ids)
      |> Repo.all()

    for podcast <- podcasts, do: Podcast.cache_thumbnail_image(podcast)

    from(p in Podcast, where: p.id in ^podcast_ids)
    |> Repo.update_all(set: [thumbnailed: true])
  end

  def cache_thumbnail_image(podcast) do
    with {:error, _} <- Image.download_thumbnail("podcast", podcast.id, podcast.image_url) do
      Podcast.clear_image_url(podcast)
    end
  end

  def clear_image_url(podcast) do
    podcast
    |> Podcast.changeset(%{image_url: nil})
    |> Repo.update()
  end

  def unretire(podcast) do
    podcast
    |> Podcast.changeset(%{retired: false, failure_count: 0})
    |> Repo.update()
  end

  def get_by_id(id) do
    Repo.get!(Podcast, id)
  end

  def get_by_id_with_feeds(id) do
    Repo.get!(Podcast, id)
    |> Repo.preload(:feeds)
  end

  def get_by_id_for_show(id) do
    Repo.get!(Podcast, id)
    |> Repo.preload([:languages, :feeds, :categories])
    |> Repo.preload(engagements: :persona)
  end

  def ids_by_category_id(id) do
    from(c in Category,
      join: p in assoc(c, :podcasts),
      where: c.id == ^id and (not p.blocked or is_nil(p.blocked)),
      select: p.id
    )
    |> Repo.all()
  end

  @doc """
  Title search for "pick an existing podcast" pickers (e.g. the moderator
  "add existing podcast to moderation" flow) — a plain, unanchored
  `ILIKE "%term%"`, not the Manticore full-text index used by the public
  search page. Excludes blocked podcasts, same as `ids_by_category_id/1`.
  """
  def search_by_title(term, limit \\ 15) do
    from(p in Podcast,
      where: ilike(p.title, ^"%#{term}%") and (not p.blocked or is_nil(p.blocked)),
      order_by: p.title,
      limit: ^limit,
      select: [:id, :title]
    )
    |> Repo.all()
  end

  def all() do
    Repo.all(Podcast, order_by: :title)
  end

  def random() do
    from(p in Podcast,
      order_by: fragment("RANDOM()"),
      limit: 1,
      preload: [:episodes, :categories]
    )
    |> Repo.one()
  end

  def random(n) do
    from(p in Podcast,
      order_by: fragment("RANDOM()"),
      limit: ^n,
      preload: [:episodes, :categories]
    )
    |> Repo.all()
  end

  def stale(sort_by, sort_order, limit) do
    from(p in Podcast,
      where:
        p.next_update <= ^now() and
          not p.update_paused and not p.retired,
      join: f in assoc(p, :feeds),
      limit: ^limit,
      order_by: [{^sort_order, ^sort_by}],
      select: %{
        id: p.id,
        title: p.title,
        updated_at: p.updated_at,
        update_intervall: p.update_intervall,
        feed_url: f.self_link_url,
        next_update: p.next_update,
        failure_count: p.failure_count
      }
    )
    |> Repo.all()
  end

  def count_stale() do
    from(p in Podcast,
      where:
        p.next_update <= ^now() and
          not p.update_paused and not p.retired
    )
    |> Repo.aggregate(:count)
  end

  def likes(id) do
    get_by_id(id).likes_count
  end

  def follows(id) do
    get_by_id(id).followers_count
  end

  def get_by_category_id_and_language(category_id, nil, page, per_page) do
    from(l in Language,
      right_join: p in assoc(l, :podcasts),
      join: c in assoc(p, :categories),
      where: c.id == ^category_id,
      select: %{id: p.id, title: p.title, language_name: l.name, language_emoji: l.emoji},
      order_by: p.title,
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def get_by_category_id_and_language(category_id, language, page, per_page) do
    from(l in Language,
      right_join: p in assoc(l, :podcasts),
      join: c in assoc(p, :categories),
      where: c.id == ^category_id and l.emoji == ^language.emoji,
      select: %{id: p.id, title: p.title, language_name: l.name, language_emoji: l.emoji},
      order_by: p.title,
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def get_all_by_category_id_and_language(category_id) do
    from(l in Language,
      right_join: p in assoc(l, :podcasts),
      join: c in assoc(p, :categories),
      where: c.id == ^category_id,
      select: %{id: p.id, title: p.title, language_name: l.name, language_emoji: l.emoji}
    )
    |> Repo.all()
  end

  def get_deprecated(amount) do
    ranked_episodes =
      from(episode in Episode,
        select: %{
          id: episode.id,
          row_number: over(row_number(), :posts_partition)
        },
        windows: [
          posts_partition: [
            partition_by: :podcast_id,
            order_by: [desc_nulls_last: :publishing_date]
          ]
        ]
      )

    most_recent_episode =
      from(episode in Episode,
        join: ranked_episode in subquery(ranked_episodes),
        on: episode.id == ranked_episode.id and ranked_episode.row_number == 1,
        join: enclosure in assoc(episode, :enclosures),
        on: episode.id == enclosure.episode_id,
        select: %{
          id: episode.id,
          title: episode.title,
          link: episode.link,
          url: enclosure.url
        }
      )

    # Podcasts belonging to any community must never be deleted by this
    # mechanism (hard requirement, see backlog.md) — a podcast is
    # community-affiliated if any of its categories belongs to a Community.
    community_podcast_ids =
      from(c in Community,
        join: category in assoc(c, :category),
        join: p in assoc(category, :podcasts),
        select: p.id
      )

    deprecated_podcasts =
      from(podcast in Podcast,
        where:
          podcast.retired == true and
            podcast.id not in subquery(community_podcast_ids),
        limit: ^amount,
        order_by: [asc_nulls_first: podcast.last_build_date],
        preload: [episodes: ^most_recent_episode]
      )
      |> Repo.all(timeout: 60_000)

    deprecated_podcasts
    |> Enum.map(&probe_deprecated/1)
    |> Enum.map(&recommend_action/1)
  end

  @dead_status_codes [
    :nxdomain,
    400,
    403,
    404,
    409,
    410,
    500,
    503,
    "invalid redirection",
    "TLS alert",
    :closed,
    "closed",
    :ehostunreach,
    :econnrefused,
    :timeout,
    :connect_timeout,
    "max_redirect_overflow"
  ]

  # Probe both the feed itself and the newest episode's enclosure, rather
  # than just one or the other — see backlog.md's discussion. The 9 failed
  # scheduled updates that led to retirement already tell us plenty about
  # the *feed* specifically; re-checking it here (often much later, since a
  # podcast sits retired indefinitely until someone visits this page) is a
  # fresh temporal sample, not a repeat. Checking the episode enclosure too
  # adds a genuinely different signal (episode files can outlive a dead
  # feed generator on some hosts, or rot independently via CDN/signed-URL
  # expiry even while the feed is fine) that the feed check alone can't see.
  defp probe_deprecated(dp) do
    Logger.info("Probing deprecated podcast #{dp.id}: #{dp.title}")

    feed_status_code =
      case Pan.Parser.Feed.get_by_podcast_id(dp.id) do
        {:ok, feed} -> probe_url(feed.self_link_url)
        {:error, _reason} -> nil
      end

    episode_status_code = probe_url(Enum.at(dp.episodes, 0).url)

    dp
    |> Map.put(:feed_status_code, feed_status_code)
    |> Map.put(:episode_status_code, episode_status_code)
  end

  # Pan.Parser.Download.get/2 instead of a raw HTTPoison call — same TLS
  # 1.3-handshake-quirk fallback retry and hackney-crash rescue the regular
  # feed-update path already benefits from, see backlog.md.
  defp probe_url(url) do
    try do
      case Pan.Parser.Download.get(url, follow_redirect: true) do
        {:ok, response} ->
          response.status_code

        {:error, %HTTPoison.Error{reason: reason, id: nil}} ->
          case reason do
            {:invalid_redirection, _} -> "invalid redirection"
            {:tls_alert, _} -> "TLS alert"
            {:closed, ""} -> "closed"
            {:max_redirect_overflow, _} -> "max_redirect_overflow"
            _ -> reason
          end
      end
    rescue
      _e in CaseClauseError -> "CaseClauseError"
      e -> e.__exception__
    end
  end

  # Computes a *recommendation* only — never mutates anything. Loading
  # /podcasts/deprecated used to delete/unretire automatically as a side
  # effect of the page render; now it only probes and suggests, and an
  # admin has to click the matching button (PodcastController.delete/2 /
  # unretire/2 — both already existed and already do the right cleanup) to
  # actually commit it. See backlog.md.
  #
  # Recommend unretiring as soon as the *feed* is reachable again — that's
  # the thing Pan actually needs in order to resume tracking, regardless of
  # the episode probe. Only recommend deleting when *both* signals
  # independently agree there's nothing left. Feed dead but episode still
  # reachable (or any other combination) is the genuinely ambiguous middle
  # case: no recommendation, worth a human glance rather than a guess.
  defp recommend_action(dp) do
    cond do
      dp.feed_status_code == 200 ->
        Map.put(dp, :recommended_action, :unretire)

      dp.feed_status_code in @dead_status_codes and dp.episode_status_code in @dead_status_codes ->
        Map.put(dp, :recommended_action, :delete)

      true ->
        Map.put(dp, :recommended_action, :inconclusive)
    end
  end
end
