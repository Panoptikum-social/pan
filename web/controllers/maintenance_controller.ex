defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.CategoryPodcast
  alias Pan.Subscription
  alias Pan.Message
  alias Pan.Gig
  alias Pan.Podcast


  def trigger_import(conn, params) do
    ten_hours_ago = Pan.Parser.Helpers.ten_hours_ago()

    newest_podcast = from(p in Podcast, where: p.updated_at <= ^ten_hours_ago and
                                               (is_nil(p.update_paused) or p.update_paused == false) and
                                               (is_nil(p.retired) or p.retired == false),
                                        limit: 1,
                                        order_by: [desc: :updated_at])
                     |> Repo.one()


    newest_plus_one_sec = newest_podcast.updated_at
                          |> Ecto.DateTime.to_erl()
                          |> Timex.to_datetime("Etc/UTC")
                          |> Timex.shift(seconds: 1)
                          |> Timex.to_erl()
                          |> Ecto.DateTime.from_erl()


    from(p in Podcast, where: p.updated_at <= ^ten_hours_ago and
                              (is_nil(p.update_paused) or p.update_paused == false) and
                              (is_nil(p.retired) or p.retired == false),
                       limit: 1,
                       order_by: [asc: :updated_at])
    |> Repo.one()
    |> Podcast.changeset(%{updated_at: newest_plus_one_sec})
    |> Repo.update()


    Task.async(fn ->
      Pan.PodcastController.delta_import_all(conn, params)
    end)

    conn
    |> put_flash(:info, "Podcasts import started.")
    |> redirect(to: podcast_path(conn, :index))
  end


  def remove_duplicates(conn, _params) do
    duplicates = from(a in CategoryPodcast, group_by: [a.category_id, a.podcast_id],
                                            select: [a.category_id, a.podcast_id, count(a.podcast_id)],
                                            having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [category_id, podcast_id, _count] <- duplicates do
      from(a in CategoryPodcast, where: a.category_id == ^category_id and
                                        a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%CategoryPodcast{podcast_id: podcast_id,
                                    category_id: category_id})
    end

    duplicates = from(a in Subscription, group_by: [a.user_id, a.podcast_id],
                                         select: [a.user_id, a.podcast_id, count(a.podcast_id)],
                                         having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [user_id, podcast_id, _count] <- duplicates do
      from(a in Subscription, where: a.user_id == ^user_id and
                                     a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%Subscription{podcast_id: podcast_id,
                                 user_id: user_id})
    end

    render(conn, "remove_duplicates.html", %{})
  end


  def message_cleanup(conn, _params) do
    from(m in Message, where: m.event in ["follow", "subscribe"])
    |> Repo.delete_all()

    render(conn, "message_cleanup.html", %{})
  end


  def remove_duplicate_gigs(conn, _params) do
    duplicates = from(g in Gig, group_by: [g.role, g.episode_id, g.persona_id,],
                                select: [g.role, g.episode_id, g.persona_id, count(g.persona_id)],
                                having: count(g.persona_id) > 1)
                 |> Repo.all()

    for [role, episode_id, persona_id, count] <- duplicates do
      one_less = count - 1

      gig_ids = from(g in Gig, where: g.role == ^role and
                                      g.episode_id == ^episode_id and
                                      g.persona_id == ^persona_id,
                               limit: ^one_less,
                               order_by: [asc: g.inserted_at],
                               select: g.id)
                    |> Repo.all()

      from(g in Gig, where: g.id in ^gig_ids)
      |> Repo.delete_all()
    end

    render(conn, "remove_duplicates.html")
  end
end
