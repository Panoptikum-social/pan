defmodule PanWeb.Api.PodcastController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Episode, Like, Podcast, Subscription, User}
  import PanWeb.Api.Helpers, only: [send_504: 2, add_etag_header: 2]

  import Pan.Parser.MyDateTime,
    only: [now: 0, in_the_future?: 1, time_shift: 2, time_diff: 3, in_the_past?: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total =
      from(p in Podcast, where: not p.blocked)
      |> Repo.aggregate(:count)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_podcast_url(:index)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcasts =
      from(p in Podcast,
        order_by: [desc: :inserted_at],
        where: not p.blocked,
        preload: [:categories, :languages, :engagements, :contributors],
        limit: ^size,
        offset: ^offset
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: podcasts,
      opts: [page: links, include: "categories,engagements,contributors,languages"]
    )
  end

  def show(conn, %{"id" => id} = params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total =
      from(e in PanWeb.Episode, where: e.podcast_id == ^id)
      |> Repo.aggregate(:count)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_podcast_url(:show, id)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcast =
      Repo.get(Podcast, id)
      |> Repo.preload(
        episodes:
          from(e in Episode,
            order_by: [desc: e.publishing_date],
            offset: ^offset,
            limit: ^size
          )
      )
      |> Repo.preload([
        :categories,
        :languages,
        :engagements,
        :contributors,
        [recommendations: :user],
        :feeds,
        [episodes: :enclosures]
      ])

    if podcast do
      includes =
        "episodes.enclosures,categories,languages,engagements,contributors,recommendations,feeds"

      podcast_json =
        PanWeb.Api.PodcastView
        |> JaSerializer.format(podcast, conn, include: includes)
        |> Jason.encode!()

      conn
      |> add_etag_header(podcast_json)
      |> render("show.json-api",
        data: podcast,
        opts: [page: links, include: includes]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def trigger_update(conn, %{"id" => id} = params, _user) do
    podcast = Repo.get!(Podcast, id)

    if podcast.update_paused do
      Helpers.send_error(
        conn,
        424,
        "Podcast paused",
        "The podcast could not be parsed 10 times in a row and we do not update it's data currently."
      )
    else
      if !podcast.manually_updated_at or
           NaiveDateTime.add(podcast.manually_updated_at, 3600, :second)
           |> in_the_future?() do
        podcast
        |> Podcast.changeset(%{manually_updated_at: now()})
        |> Repo.update()

        Pan.Parser.Podcast.update_from_feed(podcast)
        show(conn, params, nil)
      else
        minutes =
          time_shift(podcast.manually_updated_at, hours: 1)
          |> time_diff(now(), :minutes)

        Helpers.send_error(
          conn,
          429,
          "Too many requests",
          "The next update on this podcast is available in #{minutes} minutes."
        )
      end
    end
  end

  def trigger_episode_update(conn, %{"id" => id} = params, _user) do
    podcast = Repo.get!(Podcast, id)

    if podcast.update_paused do
      Helpers.send_error(
        conn,
        424,
        "Podcast paused",
        "The podcast could not be parsed 10 times in a row and we do not update it's data currently."
      )
    else
      if !podcast.manually_updated_at or
           time_shift(podcast.manually_updated_at, hours: 1) |> in_the_past?() do
        Podcast.changeset(podcast, %{manually_updated_at: time_shift(now(), minutes: -30)})
        |> Repo.update()

        case Pan.Updater.Podcast.import_new_episodes(
               podcast,
               :not_forced,
               :no_failure_count_increase
             ) do
          {:ok, _} -> show(conn, params, nil)
          {:error, message} -> send_504(conn, message)
        end
      else
        minutes =
          time_shift(podcast.manually_updated_at, hours: 1)
          |> time_diff(now(), :minutes)

        Helpers.send_error(
          conn,
          429,
          "Too many requests",
          "The next update on this podcast is available in #{minutes} minutes."
        )
      end
    end
  end

  def last_updated(conn, params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total =
      from(p in Podcast,
        where:
          not p.blocked and
            not is_nil(p.latest_episode_publishing_date) and
            p.latest_episode_publishing_date < ^now()
      )
      |> Repo.aggregate(:count)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_podcast_url(:last_updated)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcasts =
      from(p in Podcast,
        where:
          not p.blocked and
            not is_nil(p.latest_episode_publishing_date) and
            p.latest_episode_publishing_date < ^now(),
        order_by: [desc: :latest_episode_publishing_date],
        limit: ^size,
        offset: ^offset
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: podcasts,
      opts: [page: links]
    )
  end

  def most_subscribed(conn, _params, _user) do
    podcasts =
      from(p in Podcast,
        order_by: [desc: p.subscriptions_count],
        limit: 10
      )
      |> Repo.all()

    render(conn, "index.json-api", data: podcasts)
  end

  def most_liked(conn, _params, _user) do
    podcasts =
      from(p in Podcast,
        order_by: [desc: p.likes_count],
        limit: 10
      )
      |> Repo.all()

    render(conn, "index.json-api", data: podcasts)
  end

  def search(conn, params, _user) do
    page =
      Map.get(params, "page", %{})
      |> Map.get("number", "1")
      |> String.to_integer()

    size =
      Map.get(params, "page", %{})
      |> Map.get("size", "10")
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    hits =
      Pan.Search.query(index: "podcasts", term: params["filter"], limit: size, offset: offset)

    if hits["total"] > 0 do
      total = Enum.min([hits["total"], 10_000])
      total_pages = div(total - 1, size) + 1

      links =
        conn
        |> api_podcast_url(:search)
        |> Helpers.pagination_links({page, size, total_pages}, conn)

      podcast_ids = Enum.map(hits["hits"], fn hit -> String.to_integer(hit["_id"]) end)

      podcasts =
        from(p in Podcast,
          where: p.id in ^podcast_ids,
          preload: [:categories, :languages, :engagements, :contributors]
        )
        |> Repo.all()

      render(conn, "index.json-api",
        data: podcasts,
        opts: [page: links, include: "categories,engagements,contributors,languages"]
      )
    else
      Helpers.send_error(
        conn,
        404,
        "Nothing found",
        "No matching podcasts found in the data base."
      )
    end
  end

  def i_like(conn, _params, user) do
    podcast_ids =
      from(l in Like,
        where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
        select: l.podcast_id
      )
      |> Repo.all()

    podcasts =
      from(p in Podcast,
        where: p.id in ^podcast_ids,
        order_by: :title,
        preload: [:categories, :engagements, :contributors, :languages]
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: podcasts,
      opts: [include: "categories,engagements,contributors,languages"]
    )
  end

  def i_follow(conn, _params, user) do
    user =
      Repo.get(User, user.id)
      |> Repo.preload(podcasts_i_follow: from(p in Podcast, order_by: p.title))

    podcasts =
      user.podcasts_i_follow
      |> Repo.preload([:categories, :engagements, :contributors, :languages])

    render(conn, "index.json-api",
      data: podcasts,
      opts: [include: "categories,engagements,contributors,languages"]
    )
  end

  def i_subscribed(conn, _params, user) do
    user =
      Repo.get(User, user.id)
      |> Repo.preload(podcasts_i_subscribed: from(p in Podcast, order_by: p.title))

    podcasts =
      user.podcasts_i_subscribed
      |> Repo.preload([:categories, :engagements, :contributors, :languages])

    render(conn, "index.json-api",
      data: podcasts,
      opts: [include: "categories,engagements,contributors,languages"]
    )
  end

  def also_listened_to(conn, _params, user) do
    podcasts_subscribed_ids =
      from(s in Subscription,
        where: s.user_id == ^user.id,
        select: s.podcast_id
      )
      |> Repo.all()

    other_subscriber_ids =
      from(s in Subscription,
        where: s.podcast_id in ^podcasts_subscribed_ids,
        select: s.user_id
      )
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(user.id)

    podcast_ids =
      from(s in Subscription,
        join: p in assoc(s, :podcast),
        where:
          s.user_id in ^other_subscriber_ids and
            s.podcast_id not in ^podcasts_subscribed_ids,
        group_by: p.id,
        select: p.id,
        order_by: [desc: count(s.podcast_id)],
        limit: 10
      )
      |> Repo.all()

    podcasts =
      from(p in Podcast,
        where: p.id in ^podcast_ids,
        preload: [:categories, :engagements, :contributors, :languages]
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: podcasts,
      opts: [include: "categories,engagements,contributors,languages"]
    )
  end

  def also_liked(conn, _params, user) do
    podcast_i_like_ids =
      from(l in Like,
        where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
        select: l.podcast_id
      )
      |> Repo.all()

    users_also_liking =
      from(l in Like,
        where: l.podcast_id in ^podcast_i_like_ids,
        select: l.enjoyer_id
      )
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(user.id)

    podcast_ids =
      from(l in Like,
        join: p in assoc(l, :podcast),
        where:
          l.enjoyer_id in ^users_also_liking and
            l.podcast_id not in ^podcast_i_like_ids,
        group_by: p.id,
        select: p.id,
        order_by: [desc: count(l.podcast_id)],
        limit: 10
      )
      |> Repo.all()

    podcasts =
      from(p in Podcast,
        where: p.id in ^podcast_ids,
        preload: [:categories, :engagements, :contributors, :languages]
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: podcasts,
      opts: [include: "categories,engagements,contributors,languages"]
    )
  end
end
