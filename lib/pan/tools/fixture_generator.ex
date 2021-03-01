defmodule Pan.Tools.FixtureGenerator do
  import Ecto.Query
  alias Pan.Repo

  alias PanWeb.{
    AlternateFeed,
    CategoryPodcast,
    Chapter,
    Delegation,
    Enclosure,
    Engagement,
    Episode,
    Feed,
    FeedBacklog,
    Follow,
    Gig,
    Invoice,
    Like,
    Manifestation,
    Message,
    Opml,
    Persona,
    Podcast,
    Recommendation,
    Subscription,
    User
  }

  def drill_down do
    Repo.delete_all(Like)
    Repo.delete_all(Subscription)
    Repo.delete_all(Recommendation)
    Repo.delete_all(Message)
    Repo.delete_all(Manifestation)
    Repo.delete_all(Opml)
    Repo.delete_all(FeedBacklog)
    Repo.delete_all(Follow)
    Repo.delete_all(Invoice)
    Repo.delete_all(User)

    episode_ids =
      from(e in Episode,
        where: e.podcast_id > 250,
        select: e.id
      )
      |> Repo.all()

    from(e in Enclosure, where: e.episode_id in ^episode_ids)
    |> Repo.delete_all()

    from(c in Chapter, where: c.episode_id in ^episode_ids)
    |> Repo.delete_all()

    from(g in Gig, where: g.episode_id in ^episode_ids)
    |> Repo.delete_all()

    from(e in Episode, where: e.podcast_id > 250)
    |> Repo.delete_all()

    from(e in Engagement, where: e.podcast_id > 250)
    |> Repo.delete_all()

    from(cp in CategoryPodcast, where: cp.podcast_id > 250)
    |> Repo.delete_all()

    feed_ids =
      from(f in Feed,
        where: f.podcast_id > 250,
        select: f.id
      )
      |> Repo.all()

    from(a in AlternateFeed, where: a.feed_id in ^feed_ids)
    |> Repo.delete_all()

    from(f in Feed, where: f.podcast_id > 250)
    |> Repo.delete_all()

    from(lp in "languages_podcasts", where: lp.podcast_id > 250)
    |> Repo.delete_all()

    from(p in Podcast, where: p.id > 250)
    |> Repo.delete_all()

    ids_with_gigs =
      from(g in Gig,
        group_by: g.persona_id,
        select: g.persona_id
      )
      |> Repo.all()

    ids_with_engagements =
      from(e in Engagement,
        group_by: e.persona_id,
        select: e.persona_id
      )
      |> Repo.all()

    persona_ids = ids_with_gigs ++ ids_with_engagements

    from(d in Delegation, where: d.persona_id not in ^persona_ids)
    |> Repo.delete_all()

    from(d in Delegation, where: d.delegate_id not in ^persona_ids)
    |> Repo.delete_all()

    from(p in Persona, where: p.id not in ^persona_ids)
    |> Repo.delete_all()
  end
end
