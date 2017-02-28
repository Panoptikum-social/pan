defmodule Pan.PodcastController do
  use Pan.Web, :controller
  alias Pan.Episode

  alias Pan.Podcast

  plug :scrub_params, "podcast" when action in [:create, :update]

  def orphans(conn, _params) do
    podcast_ids = from(a in "categories_podcasts", group_by: a.podcast_id,
                                                   select:   a.podcast_id)
                  |> Repo.all

    unassigned_podcasts = from(p in Podcast, where: not p.id in ^podcast_ids)
                          |> Repo.all

    podcast_ids = from(e in Episode, group_by: e.podcast_id,
                                     select:   e.podcast_id)
                  |> Repo.all

    podcasts_without_episodes = from(p in Podcast, where: not p.id in ^podcast_ids)
                                |> Repo.all


    render(conn, "orphans.html", unassigned_podcasts: unassigned_podcasts,
                                 podcasts_without_episodes: podcasts_without_episodes)
  end


  def index(conn, _params) do
    ten_hours_ago = Timex.now()
                    |> Timex.shift(hours: -10)

    stale = from(p in Podcast, where: p.updated_at <= ^ten_hours_ago and
                                      (is_nil(p.update_paused) or p.update_paused == false) and
                                      (is_nil(p.retired) or p.retired == false))
            |> Repo.aggregate(:count, :id)

    paused = from(p in Podcast, where: (p.update_paused == true) and
                                       (is_nil(p.retired) or p.retired == false))
             |> Repo.aggregate(:count, :id)

    retired = from(p in Podcast, where: p.retired == true)
              |> Repo.aggregate(:count, :id)

    render(conn, "index.html", stale: stale,
                                paused: paused,
                                retired: retired)
  end

  def datatable(conn, _params) do
    podcasts = from(p in Podcast, order_by: [asc: :updated_at],
                                  join: e in assoc(p, :engagements),
                                  where: e.role == "author",
                                  join: persona in assoc(e, :persona),
                                  select: %{id: p.id,
                                            title: p.title,
                                            author_name: persona.name,
                                            update_paused: p.update_paused,
                                            website: p.website})
               |> Repo.all
    render conn, "datatable.json", podcasts: podcasts
  end


  def factory(conn, _params) do
    podcasts = from(p in Podcast, order_by: [asc: :updated_at],
                                  where: p.update_paused == true and
                                         (is_nil(p.retired) or p.retired == false),
                                  preload: :feeds)
               |> Repo.all()

    render(conn, "factory.html", podcasts: podcasts)
  end


  def new(conn, _params) do
    changeset = Podcast.changeset(%Podcast{})
    render(conn, "new.html", changeset: changeset)
  end


  def create(conn, %{"podcast" => podcast_params}) do
    changeset = Podcast.changeset(%Podcast{}, podcast_params)

    case Repo.insert(changeset) do
      {:ok, _podcast} ->
        conn
        |> put_flash(:info, "Podcast created successfully.")
        |> redirect(to: podcast_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(episodes: from(e in Episode, order_by: [desc: e.publishing_date]))
              |> Repo.preload(episodes: :podcast)
              |> Repo.preload(feeds: :podcast)
              |> Repo.preload([:languages, :categories, :contributors])

    render(conn, "show.html", podcast: podcast)
  end


  def edit(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast)
    render(conn, "edit.html", podcast: podcast, changeset: changeset)
  end


  def update(conn, %{"id" => id, "podcast" => podcast_params}) do
    podcast = Repo.get!(Podcast, id)
    changeset = Podcast.changeset(podcast, podcast_params)

    case Repo.update(changeset) do
      {:ok, podcast} ->
        conn
        |> put_flash(:info, "Podcast updated successfully.")
        |> redirect(to: podcast_path(conn, :show, podcast))
      {:error, changeset} ->
        render(conn, "edit.html", podcast: podcast, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}) do
    podcast = Repo.get!(Podcast, id)
              |> Repo.preload(episodes: :chapters)
              |> Repo.preload(:feeds)

    for episode <- podcast.episodes do
      for chapter <- episode.chapters do
        Repo.delete_all(from l in Pan.Like,           where: l.chapter_id == ^chapter.id)
        Repo.delete_all(from r in Pan.Recommendation, where: r.chapter_id == ^chapter.id)
      end
      Repo.delete_all(from c in Pan.Chapter,   where: c.episode_id == ^episode.id)
      Repo.delete_all(from e in Pan.Enclosure, where: e.episode_id == ^episode.id)
      Repo.delete_all(from g in Pan.Gig,       where: g.episode_id == ^episode.id)
    end

    for feed <- podcast.feeds do
      Repo.delete_all(from a in Pan.AlternateFeed, where: a.feed_id == ^feed.id)
    end

    Repo.delete_all(from l in Pan.Like,    where: l.podcast_id == ^podcast.id)
    Repo.delete_all(from f in Pan.Follow,  where: f.podcast_id == ^podcast.id)
    Repo.delete_all(from e in Pan.Episode, where: e.podcast_id == ^podcast.id)

    Repo.delete!(podcast)

    conn
    |> put_flash(:info, "Podcast deleted successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def delta_import(conn, %{"id" => id}) do
    case Pan.Parser.Podcast.delta_import(id) do
      {:ok, message} ->
        conn
        |> put_flash(:info, message)
      {:error, message} ->
        conn
        |> put_flash(:error, message)
    end
    |> redirect(to: podcast_path(conn, :show, id))
  end


  def contributor_import(conn, %{"id" => id}) do
    case Pan.Parser.Podcast.contributor_import(id) do
      {:ok, message} ->
        conn
        |> put_flash(:info, message)
      {:error, message} ->
        conn
        |> put_flash(:error, message)
    end
    |> redirect(to: podcast_path(conn, :show, id))
  end


  def fix_owner(conn, %{"id" => id}) do
    Pan.Parser.Podcast.fix_owner(id)

    conn
    |> put_flash(:info, "Owner fixed successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def delta_import_all(conn, _params) do
    current_user = conn.assigns.current_user
    ten_hours_ago = Timex.now()
                    |> Timex.shift(hours: -10)

    podcasts = from(p in Podcast, where: p.updated_at <= ^ten_hours_ago and
                                         (is_nil(p.update_paused) or p.update_paused == false) and
                                         (is_nil(p.retired) or p.retired == false),
                                  order_by: [asc: :updated_at])
               |> Repo.all()

    for podcast <- podcasts do
      # Task.async(fn -> delta_import_one(podcast, current_user) end)
      Podcast.delta_import_one(podcast, current_user)
    end

    conn
    |> put_flash(:info, "Podcasts updated successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def touch(conn, %{"id" => id}) do
    Repo.get!(Podcast, id)
    |> Pan.Podcast.changeset
    |> Repo.update([force: true])

    conn
    |> put_flash(:info, "Podcast touched.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def pause(conn, %{"id" => id}) do
    from(p in Podcast, where: p.id == ^id)
    |> Repo.update_all(set: [update_paused: true])

    conn
    |> put_flash(:info, "Podcast paused.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def retirement(conn, _params) do
    candidates = from(p in Podcast, where: is_nil(p.retired) or p.retired == false,
                                    join: e in assoc(p, :episodes),
                                    group_by: [p.id],
                                    having: max(e.publishing_date) < ago(1, "year"),
                                    select: %{id: p.id,
                                              title: p.title,
                                              last_build_date: p.last_build_date,
                                              last_episode_date: max(e.publishing_date)},
                                    order_by: max(e.publishing_date))
                 |> Repo.all()

    retired = from(p in Podcast, where: p.retired == true)
              |> Repo.all

    render(conn, "retirement.html", candidates: candidates,
                                    retired: retired)
  end


  def retire(conn, %{"id" => id}) do
    from(p in Podcast, where: p.id == ^id)
    |> Repo.update_all(set: [retired: true])

    conn
    |> put_flash(:info, "Podcast retired.")
    |> redirect(to: podcast_path(conn, :retirement))
  end
end