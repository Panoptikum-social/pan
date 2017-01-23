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
    podcasts = from(p in Podcast, order_by: [asc: :updated_at],
                                  preload: [:feeds])
               |> Repo.all


    stale = from(p in Podcast, where: p.updated_at <= ^ten_hours_ago() and
                                      (is_nil(p.update_paused) or p.update_paused == false))
            |> Repo.aggregate(:count, :id)

    paused = from(p in Podcast, where: p.update_paused == true)
             |> Repo.aggregate(:count, :id)

    render(conn, "index.html", podcasts: podcasts, stale: stale, paused: paused)
  end


  def factory(conn, _params) do
    podcasts = from(p in Podcast, order_by: [asc: :updated_at],
                                  where: p.update_paused == true,
                                  preload: [:feeds])
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
              |> Repo.preload(episodes: from(e in Episode, order_by: e.title))
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
    |> redirect(to: podcast_path(conn, :factory))
  end


  def fix_owner(conn, %{"id" => id}) do
    Pan.Parser.Podcast.fix_owner(id)

    conn
    |> put_flash(:info, "Owner fixed successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def delta_import_all(conn, _params) do
    current_user = conn.assigns.current_user
    podcasts = from(p in Podcast, where: p.updated_at <= ^ten_hours_ago() and
                                         (is_nil(p.update_paused) or p.update_paused == false),
                                  order_by: [asc: :updated_at])
               |> Repo.all()

    for podcast <- podcasts do
      # Task.async(fn -> delta_import_one(podcast, current_user) end)
      delta_import_one(podcast, current_user)
    end

    conn
    |> put_flash(:info, "Podcasts updated successfully.")
    |> redirect(to: podcast_path(conn, :index))
  end

  defp delta_import_one(podcast, current_user) do
    notification = case Pan.Parser.Podcast.delta_import(podcast.id) do
      {:ok, _} ->
        %{content: "Updated Podcast " <> podcast.title,
          type: "success",
          user_name: current_user.name}

      {:error, message} ->
        %{content: "Error:" <> message <> " / updating podcast" <> podcast.title,
          type: "danger",
          user_name: current_user.name}
    end

    Pan.Endpoint.broadcast "mailboxes:" <> Integer.to_string(current_user.id),
                           "notification", notification
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


  defp ten_hours_ago do
    Timex.now()
    |> Timex.shift(hours: -10)
    |> Timex.to_erl()
    |> Ecto.DateTime.from_erl()
  end
end
