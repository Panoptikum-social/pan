defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.CategoryPodcast
  alias Pan.Subscription
  alias Pan.Message
  alias Pan.Episode
  alias Pan.Enclosure
  alias Pan.Gig
  alias Pan.Chapter
  alias Pan.Like

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


  def remove_duplicate_episodes(conn, _params) do
    duplicates = from(e in Episode, group_by: [e.title, e.podcast_id],
                                    select: [e.title, e.podcast_id, count(e.podcast_id)],
                                    having: count(e.podcast_id) > 1)
                 |> Repo.all()

    for [title, podcast_id, count] <- duplicates do
      one_less = count - 1

      episode_ids = from(e in Episode, where: e.title == ^title and
                                              e.podcast_id == ^podcast_id,
                                       limit: ^one_less,
                                       order_by: [asc: e.publishing_date],
                                       select: e.id)
                    |> Repo.all()

      from(e in Enclosure, where: e.episode_id in ^episode_ids)
      |> Repo.delete_all()

      from(g in Gig, where: g.episode_id in ^episode_ids)
      |> Repo.delete_all()

      from(c in Chapter, where: c.episode_id in ^episode_ids)
      |> Repo.delete_all()

      from(l in Like, where: l.episode_id in ^episode_ids)
      |> Repo.delete_all()

      from(e in Episode, where: e.id in ^episode_ids)
      |> Repo.delete_all()
    end

    render(conn, "remove_duplicate_episodes.html")
  end
end
