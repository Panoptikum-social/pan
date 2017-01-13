defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.CategoryPodcast
  alias Pan.Subscription
  alias Pan.ContributorPodcast
  alias Pan.ContributorEpisode
  alias Pan.Message

  def remove_duplicates(conn, _params) do
    duplicates = from(a in CategoryPodcast, group_by: [a.category_id, a.podcast_id],
                                            select: [a.category_id, a.podcast_id, count(a.podcast_id)],
                                            having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [category_id, podcast_id, count] = duplicate <- duplicates do
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

    for [user_id, podcast_id, count] = duplicate <- duplicates do
      from(a in Subscription, where: a.user_id == ^user_id and
                                     a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%Subscription{podcast_id: podcast_id,
                                 user_id: user_id})
    end

    duplicates = from(a in ContributorPodcast, group_by: [a.contributor_id, a.podcast_id],
                                               select: [a.contributor_id, a.podcast_id, count(a.podcast_id)],
                                               having: count(a.podcast_id) > 1)
                 |> Repo.all()

    for [contributor_id, podcast_id, count] = duplicate <- duplicates do
      from(a in ContributorPodcast, where: a.contributor_id == ^contributor_id and
                                           a.podcast_id == ^podcast_id)
      |> Repo.delete_all()

      Repo.insert!(%ContributorPodcast{podcast_id: podcast_id,
                                       contributor_id: contributor_id})
    end

    duplicates = from(a in ContributorEpisode, group_by: [a.contributor_id, a.episode_id],
                                               select: [a.contributor_id, a.episode_id, count(a.episode_id)],
                                               having: count(a.episode_id) > 1)
                 |> Repo.all()

    for [contributor_id, episode_id, count] = duplicate <- duplicates do
      from(a in ContributorEpisode, where: a.contributor_id == ^contributor_id and
                                           a.episode_id == ^episode_id)
      |> Repo.delete_all()

      Repo.insert!(%ContributorEpisode{episode_id: episode_id,
                                       contributor_id: contributor_id})
    end

    render(conn, "remove_duplicates.html", %{})
  end


  def message_cleanup(conn, _params) do
    from(m in Message, where: m.event in ["follow", "subscribe"])
    |> Repo.delete_all()

    render(conn, "message_cleanup.html", %{})
  end
end
