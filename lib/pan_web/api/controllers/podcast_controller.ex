defmodule PanWeb.Api.PodcastController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Episode
  alias PanWeb.Podcast
  alias PanWeb.Like
  alias PanWeb.User
  alias PanWeb.Subscription
  alias PanWeb.Api.Helpers


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)

    offset = (page - 1) * size

    total = from(p in Podcast, where: is_nil(p.blocked) or p.blocked == false)
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = conn
    |> api_podcast_url(:index)
    |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcasts = from(p in Podcast, order_by: [desc: :inserted_at],
                                  where: is_nil(p.blocked) or p.blocked == false,
                                  preload: [:categories, :languages, :engagements, :contributors],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [page: links,
                                          include: "categories,engagements,contributors,languages"]
  end


  def show(conn, %{"id" => id} = params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    total = from(e in PanWeb.Episode, where: e.podcast_id == ^id)
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = conn
    |> api_podcast_url(:show, id)
    |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcast = Repo.get(Podcast, id)
               |> Repo.preload(episodes: from(e in Episode, order_by: [desc: e.publishing_date],
                                                            offset: ^offset,
                                                            limit: ^size))
               |> Repo.preload([:categories, :languages, :engagements, :contributors,
                               [recommendations: :user], :feeds, [episodes: :enclosures]])

    if podcast do
      render conn, "show.json-api", data: podcast,
                                  opts: [page: links,
                                         include: "episodes.enclosures,categories,languages,engagements,contributors,recommendations,feeds"]
    else
      Helpers.send_404(conn)
    end
  end


  def trigger_update(conn, %{"id" => id} = params, _user) do
    id = String.to_integer(id)
    podcast = Repo.get!(Podcast, id)

    if !podcast.manually_updated_at or
       (Timex.compare(Timex.shift(podcast.manually_updated_at, hours: 1), Timex.now()) == -1) do

      podcast
      |> Podcast.changeset(%{manually_updated_at: Timex.now()})
      |> Repo.update()

      Pan.Parser.Podcast.update_from_feed(id)
      show(conn, params, nil)
    else
      minutes = podcast.manually_updated_at
                |> Timex.shift(hours: 1)
                |> Timex.Comparable.diff(Timex.now(), :minutes)

      Helpers.send_error(conn, 429, "Too many requests",
                         "The next update on this podcast is available in #{minutes} minutes.")
    end
  end


  def trigger_episode_update(conn, %{"id" => id} = params, _user) do
    id = String.to_integer(id)
    podcast = Repo.get!(Podcast, id)

    if !podcast.manually_updated_at or
       (Timex.compare(Timex.shift(podcast.manually_updated_at, hours: 1), Timex.now()) == -1) do

      thirty_minutes_ago = Timex.now()
                           |> Timex.shift(minutes: -30)

      podcast
      |> Podcast.changeset(%{manually_updated_at: thirty_minutes_ago})
      |> Repo.update()

      Pan.Parser.Podcast.delta_import(id)
      show(conn, params, nil)
    else
      minutes = podcast.manually_updated_at
                |> Timex.shift(hours: 1)
                |> Timex.Comparable.diff(Timex.now(), :minutes)

      Helpers.send_error(conn, 429, "Too many requests",
                         "The next update on this podcast is available in #{minutes} minutes.")
    end
  end


  def last_updated(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    total = from(p in Podcast, where: (is_nil(p.blocked) or p.blocked == false) and
                                      is_nil(p.latest_episode_publishing_date) == false and
                                      p.latest_episode_publishing_date < ^NaiveDateTime.utc_now())
            |> Repo.aggregate(:count, :id)
    total_pages = div(total - 1, size) + 1

    links = conn
    |> api_podcast_url(:last_updated)
    |> Helpers.pagination_links({page, size, total_pages}, conn)

    podcasts = from(p in Podcast, where: (is_nil(p.blocked) or p.blocked == false) and
                                         is_nil(p.latest_episode_publishing_date) == false and
                                         p.latest_episode_publishing_date < ^NaiveDateTime.utc_now(),
                                  order_by: [desc: :latest_episode_publishing_date],
                                  limit: ^size,
                                  offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [page: links]
  end


  def most_subscribed(conn, _params, _user) do
    podcasts = from(p in Podcast, order_by: [desc: p.subscriptions_count],
                                  limit: 10)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end


  def most_liked(conn, _params, _user) do
    podcasts = from(p in Podcast, order_by: [desc: p.likes_count],
                                  limit: 10)
               |> Repo.all()

    render conn, "index.json-api", data: podcasts
  end


  def search(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/podcasts",
             search: [size: size, from: offset, query: [match: [_all: params["filter"]]]]]


    case Tirexs.Query.create_resource(query) do
      {:ok, 200, %{hits: hits}} ->
        if hits.total > 0 do
          total = Enum.min([hits.total, 10_000])
          total_pages = div(total - 1, size) + 1

          links = conn
          |> api_podcast_url(:search)
          |> Helpers.pagination_links({page, size, total_pages}, conn)

          podcast_ids = Enum.map(hits[:hits], fn(hit) -> String.to_integer(hit[:_id]) end)

          podcasts = from(p in Podcast, where: p.id in ^podcast_ids,
                                        preload: [:categories, :languages, :engagements, :contributors])
                     |> Repo.all()

          render conn, "index.json-api", data: podcasts, opts: [page: links,
                                                                include: "categories,engagements,contributors,languages"]
        else
          Helpers.send_error(conn, 404, "Nothing found", "No matching podcasts found in the data base.")
        end
      {:error, 500, %{error: %{caused_by: %{reason: reason}}}} ->
        Helpers.send_401(conn, reason)
      :error ->
        Helpers.send_error(conn, 500, "Server error", "The search engine seams to be broken right now.")
    end
  end


  def i_like(conn, _params, user) do
    podcast_ids = from(l in Like, where: l.enjoyer_id == ^user.id and
                                         is_nil(l.chapter_id) and
                                         is_nil(l.episode_id) and
                                         not is_nil(l.podcast_id),
                                  select: l.podcast_id)
                  |> Repo.all()

    podcasts = from(p in Podcast, where: p.id in ^podcast_ids,
                                  order_by: :title,
                                  preload: [:categories, :engagements, :contributors, :languages])
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [include: "categories,engagements,contributors,languages"]
  end


  def i_follow(conn, _params, user) do
    user = Repo.get(User, user.id)
           |> Repo.preload(podcasts_i_follow: from(p in Podcast, order_by: p.title))

    podcasts = user.podcasts_i_follow
               |> Repo.preload([:categories, :engagements, :contributors, :languages])

    render conn, "index.json-api", data: podcasts,
                                   opts: [include: "categories,engagements,contributors,languages"]
  end


  def i_subscribed(conn, _params, user) do
    user = Repo.get(User, user.id)
           |> Repo.preload(podcasts_i_subscribed: from(p in Podcast, order_by: p.title))

    podcasts = user.podcasts_i_subscribed
               |> Repo.preload([:categories, :engagements, :contributors, :languages])

    render conn, "index.json-api", data: podcasts,
                                   opts: [include: "categories,engagements,contributors,languages"]
  end


  def also_listened_to(conn, _params, user) do
    podcasts_subscribed_ids = from(s in Subscription, where: s.user_id == ^user.id,
                                                      select: s.podcast_id)
                              |> Repo.all()

    other_subscriber_ids = from(s in Subscription, where: s.podcast_id in ^podcasts_subscribed_ids,
                                                   select: s.user_id)
                           |> Repo.all()
                           |> Enum.uniq
                           |> List.delete(user.id)

    podcast_ids = from(s in Subscription, join: p in assoc(s, :podcast),
                                          where: s.user_id in ^other_subscriber_ids and
                                                 not s.podcast_id in ^podcasts_subscribed_ids,
                                          group_by: p.id,
                                          select: p.id,
                                          order_by: [desc: count(s.podcast_id)],
                                          limit: 10)
                  |> Repo.all()

    podcasts = from(p in Podcast, where: p.id in ^podcast_ids,
                                  preload: [:categories, :engagements, :contributors, :languages])
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [include: "categories,engagements,contributors,languages"]
  end


  def also_liked(conn, _params, user) do
    podcast_i_like_ids = from(l in Like, where: l.enjoyer_id == ^user.id and
                                                is_nil(l.chapter_id) and
                                                is_nil(l.episode_id) and
                                                not is_nil(l.podcast_id),
                                         select: l.podcast_id)
                         |> Repo.all()

    users_also_liking = from(l in Like, where: l.podcast_id in ^podcast_i_like_ids and
                                               is_nil(l.chapter_id) and
                                               is_nil(l.episode_id),
                                        select: l.enjoyer_id)
                        |> Repo.all()
                        |> Enum.uniq
                        |> List.delete(user.id)

    podcast_ids = from(l in Like, join: p in assoc(l, :podcast),
                                  where: l.enjoyer_id in ^users_also_liking and
                                         is_nil(l.chapter_id) and
                                         is_nil(l.episode_id) and
                                         not l.podcast_id in ^podcast_i_like_ids,
                                  group_by: p.id,
                                  select: p.id,
                                  order_by: [desc: count(l.podcast_id)],
                                  limit: 10)
                  |> Repo.all()

    podcasts = from(p in Podcast, where: p.id in ^podcast_ids,
                                  preload: [:categories, :engagements, :contributors, :languages])
               |> Repo.all()

    render conn, "index.json-api", data: podcasts,
                                   opts: [include: "categories,engagements,contributors,languages"]
  end
end
