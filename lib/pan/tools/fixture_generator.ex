defmodule Pan.Tools.FixtureGenerator do
# Pan.Tools.FixtureGenerator.drill_down()

  use Pan.Web, :controller

  def drill_down do
    Repo.delete_all(PanWeb.Like)
    Repo.delete_all(PanWeb.Subscription)
    Repo.delete_all(PanWeb.Recommendation)
    Repo.delete_all(PanWeb.Message)
    Repo.delete_all(PanWeb.Manifestation)
    Repo.delete_all(PanWeb.Opml)
    Repo.delete_all(PanWeb.FeedBacklog)
    Repo.delete_all(PanWeb.Follow)
    Repo.delete_all(PanWeb.Invoice)
    Repo.delete_all(PanWeb.User)

    episode_ids = (from e in PanWeb.Episode, where: e.podcast_id > 250,
                                             select: e.id)
                  |> Repo.all()

    (from e in PanWeb.Enclosure, where: e.episode_id in ^episode_ids)
    |> Repo.delete_all()

    (from c in PanWeb.Chapter, where: c.episode_id in ^episode_ids)
    |> Repo.delete_all()

    (from g in PanWeb.Gig, where: g.episode_id in ^episode_ids)
    |> Repo.delete_all()

    (from e in PanWeb.Episode, where: e.podcast_id > 250)
    |> Repo.delete_all()

    (from e in PanWeb.Engagement, where: e.podcast_id > 250)
    |> Repo.delete_all()

    (from cp in PanWeb.CategoryPodcast, where: cp.podcast_id > 250)
    |> Repo.delete_all()

    feed_ids = (from f in PanWeb.Feed, where: f.podcast_id > 250,
                                       select: f.id)
               |> Repo.all()

    (from a in PanWeb.AlternateFeed, where: a.feed_id in ^feed_ids)
    |> Repo.delete_all()

    (from f in PanWeb.Feed, where: f.podcast_id > 250)
    |> Repo.delete_all()

    (from lp in "languages_podcasts", where: lp.podcast_id > 250)
    |> Repo.delete_all()

    (from p in PanWeb.Podcast, where: p.id > 250)
    |> Repo.delete_all()

    ids_with_gigs = from(g in PanWeb.Gig, group_by: g.persona_id,
                                          select:   g.persona_id)
                     |> Repo.all()

    ids_with_engagements = from(e in PanWeb.Engagement, group_by: e.persona_id,
                                                        select:   e.persona_id)
                           |> Repo.all()

    persona_ids = ids_with_gigs ++ ids_with_engagements

    (from d in PanWeb.Delegation, where: not d.persona_id in ^persona_ids)
    |> Repo.delete_all()
    (from d in PanWeb.Delegation, where: not d.delegate_id in ^persona_ids)
    |> Repo.delete_all()

    (from p in PanWeb.Persona, where: not p.id in ^persona_ids)
    |> Repo.delete_all()
  end
end
