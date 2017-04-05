defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.CategoryPodcast
  alias Pan.Subscription
  alias Pan.Gig
  alias Pan.Episode

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.io/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2017/#{month}/#{day}/#{file}")
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

    render(conn, "done.html", %{})
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

    render(conn, "done.html", %{})
  end


  def fix_gigs(conn, _params) do
    episodes = from(e in Episode, where: is_nil(e.publishing_date))
               |> Repo.all()

    for episode <- episodes do
      Episode.changeset(episode, %{publishing_date: episode.inserted_at})
      |> Repo.update()
    end

    gigs = from(g in Gig, where: is_nil(g.publishing_date))
           |> Repo.all()

    for gig <- gigs do
      Gig.changeset(gig, %{publishing_date: gig.inserted_at})
      |> Repo.update()
    end

    render(conn, "done.html", %{})
  end
end
