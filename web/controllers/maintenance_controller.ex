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


  def remove_duplicate_enclosures(conn, _params) do
    duplicates = from(e in Enclosure, group_by: [e.url, e.episode_id],
                                      select: [e.url, e.episode_id, count(e.episode_id)],
                                      having: count(e.episode_id) > 1)
                 |> Repo.all()

    for [url, episode_id, count] <- duplicates do
      one_less = count - 1

      enclosure_ids = from(e in Enclosure, where: e.url == ^url and
                                                  e.episode_id == ^episode_id,
                                           limit: ^one_less,
                                           order_by: [asc: e.inserted_at],
                                           select: e.id)
                    |> Repo.all()

      from(e in Enclosure, where: e.id in ^enclosure_ids)
      |> Repo.delete_all()
    end

    render(conn, "remove_duplicate_episodes.html")
  end
end
