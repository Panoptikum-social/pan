defmodule PanWeb.MaintenanceController do
  use PanWeb, :controller
  import Pan.Parser.MyDateTime, only: [now: 0]

  alias PanWeb.{
    Category,
    Delegation,
    Engagement,
    Episode,
    Feed,
    FeedBacklog,
    Follow,
    Gig,
    Language,
    Like,
    Manifestation,
    Opml,
    Persona,
    Podcast,
    Recommendation,
    Subscription,
    User,
    PageFrontendView
  }

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.social/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.social/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.social/2017/#{month}/#{day}/#{file}")
  end

  def exception_notification(_conn, _params) do
    raise "exception_notification"
  end

  def catch_up_thumbnailed(conn, _paar) do
    podcast_candidates =
      from(p in Podcast,
        where: not p.thumbnailed and not is_nil(p.image_url),
        limit: 1_000,
        select: p.id
      )
      |> Repo.all()

    podcasts_missing_thumbnailed =
      from(p in Podcast,
        where: p.id in ^podcast_candidates,
        left_join: i in assoc(p, :thumbnails),
        where: not is_nil(i.podcast_id),
        select: p.id
      )
      |> Repo.all()

    from(p in Podcast, where: p.id in ^podcasts_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    persona_candidates =
      from(p in Persona,
        where: not p.thumbnailed and not is_nil(p.image_url),
        limit: 1_000,
        select: p.id
      )
      |> Repo.all()

    personas_missing_thumbnailed =
      from(p in Persona,
        where: p.id in ^persona_candidates,
        left_join: i in assoc(p, :thumbnails),
        where: not is_nil(i.persona_id),
        select: p.id
      )
      |> Repo.all()

    from(p in Persona, where: p.id in ^personas_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    render(conn, PageFrontendView, "done.html")
  end

  def stats(conn, _params) do
    stale_podcasts =
      from(p in Podcast,
        where:
          p.next_update <= ^now() and
            not p.update_paused and
            not p.retired
      )
      |> Repo.aggregate(:count)
      |> delimit_integer(" ")

    inactive_podcasts =
      from(p in Podcast, where: p.update_paused == true and not p.retired)
      |> Repo.aggregate(:count)

    retired_podcasts =
      from(p in Podcast, where: p.retired == true)
      |> Repo.aggregate(:count)

    average_update_intervall =
      from(p in Podcast, where: not p.update_paused and not p.retired)
      |> Repo.aggregate(:avg, :update_intervall)
      |> Decimal.round(2)

    total_podcasts =
      Repo.aggregate(Podcast, :count, :id)
      |> delimit_integer(" ")

    feeds_without_headers =
      from(f in Feed, where: f.no_headers_available == ^true)
      |> Repo.aggregate(:count)

    feeds_with_etag =
      from(f in Feed, where: not is_nil(f.etag))
      |> Repo.aggregate(:count)

    feeds_with_last_modified =
      from(f in Feed, where: not is_nil(f.last_modified))
      |> Repo.aggregate(:count)

    total_episodes =
      Repo.aggregate(Podcast, :sum, :episodes_count)
      |> delimit_integer(" ")

    unindexed_episodes =
      from(e in Episode, where: not e.full_text)
      |> Repo.aggregate(:count, timeout: 999_999)
      |> delimit_integer(" ")

    podcasts_per_hour =
      (Repo.aggregate(Podcast, :count, :id) - inactive_podcasts)
      |> Decimal.new()
      |> Decimal.div(average_update_intervall)
      |> Decimal.round()

    total_users = Repo.aggregate(User, :count, :id)

    total_gigs =
      Repo.aggregate(Gig, :count, :id)
      |> delimit_integer(" ")

    total_engagements =
      Repo.aggregate(Engagement, :count, :id)
      |> delimit_integer(" ")

    total_personas =
      Repo.aggregate(Persona, :count, :id)
      |> delimit_integer(" ")

    total_subscriptions =
      Repo.aggregate(Subscription, :count, :id)
      |> delimit_integer(" ")

    total_likes = Repo.aggregate(Like, :count, :id)
    total_recommendations = Repo.aggregate(Recommendation, :count, :id)
    total_categories = Repo.aggregate(Category, :count, :id)

    total_categorizations =
      Repo.aggregate("categories_podcasts", :count, :podcast_id)
      |> delimit_integer(" ")

    total_languages = Repo.aggregate(Language, :count, :id)
    total_opmls = Repo.aggregate(Opml, :count, :id)
    total_feed_backlogs = Repo.aggregate(FeedBacklog, :count, :id)
    total_follows = Repo.aggregate(Follow, :count, :id)
    total_manifestations = Repo.aggregate(Manifestation, :count, :id)
    total_delegations = Repo.aggregate(Delegation, :count, :id)

    podcasts_without_image =
      from(p in Podcast, where: not p.thumbnailed and not is_nil(p.image_url))
      |> Repo.aggregate(:count)

    podcasts_with_zero_publication_frequency =
      from(p in Podcast,
        where:
          p.publication_frequency == 0.0 and
            p.episodes_count > 1
      )
      |> Repo.aggregate(:count)

    personas_without_image =
      from(p in Persona, where: not p.thumbnailed and not is_nil(p.image_url))
      |> Repo.aggregate(:count)

    render(conn, "stats.html",
      stale_podcasts: stale_podcasts,
      inactive_podcasts: inactive_podcasts,
      retired_podcasts: retired_podcasts,
      average_update_intervall: average_update_intervall,
      total_podcasts: total_podcasts,
      total_episodes: total_episodes,
      podcasts_per_hour: podcasts_per_hour,
      total_users: total_users,
      total_gigs: total_gigs,
      total_engagements: total_engagements,
      total_personas: total_personas,
      total_subscriptions: total_subscriptions,
      total_likes: total_likes,
      total_recommendations: total_recommendations,
      total_categories: total_categories,
      total_categorizations: total_categorizations,
      total_languages: total_languages,
      total_opmls: total_opmls,
      total_feed_backlogs: total_feed_backlogs,
      total_follows: total_follows,
      total_manifestations: total_manifestations,
      total_delegations: total_delegations,
      unindexed_episodes: unindexed_episodes,
      podcasts_without_image: podcasts_without_image,
      personas_without_image: personas_without_image,
      feeds_without_headers: feeds_without_headers,
      feeds_with_etag: feeds_with_etag,
      feeds_with_last_modified: feeds_with_last_modified,
      podcasts_with_zero_publication_frequency: podcasts_with_zero_publication_frequency
    )
  end

  defp delimit_integer(number, delimiter) do
    abs(number)
    |> Integer.to_charlist()
    |> :lists.reverse()
    |> delimit_integer(delimiter, [])
  end

  defp delimit_integer([a, b, c, d | tail], delimiter, acc) do
    delimit_integer([d | tail], delimiter, [delimiter, c, b, a | acc])
  end

  defp delimit_integer(list, _, acc) do
    :lists.reverse(list) ++ acc
  end

  def populate_wisspod(conn, _params) do
    for podcast_id <- [52050, 51564, 51571, 52193, 51138, 51385, 51462, 2878, 21938, 52014, 26255, 38240, 121, 44478, 637, 51165, 51853, 52059, 51570, 379, 101, 51384, 52197, 5, 35333, 51172, 51471, 44947, 51626, 52065, 51399, 51852, 51398, 51636, 51180, 51627, 52580, 38242, 32951, 46986, 51388, 638, 52590, 51480, 52046, 11748, 51850, 46998, 51846, 13, 51574, 51635, 52217, 34588, 51136, 51477, 14, 51795, 51620, 31971, 51813, 51578, 52602, 52558, 52018, 644, 52579, 52234, 51201, 51464, 51167, 52243, 52596, 77, 51822, 51631, 51848, 51397, 51594, 51463, 51179, 51139, 52577, 51582, 51100, 24330, 51408, 49497, 13136, 645, 48781, 69, 52051, 52586, 51623, 26348, 51782, 52043, 52239, 52039, 26, 47002, 200, 51566, 52042, 51240, 51792, 640, 426, 51845, 52192, 84, 44504, 47730, 35, 42273, 51785, 52249, 52245, 52195, 51277, 51668, 52016, 38627, 51478, 38526, 51565, 51844, 265, 51392, 51168, 52589, 51420, 51854, 51581, 51276, 52236, 51414, 52216, 32952, 51847, 51279, 52516, 52205, 43401, 51575, 52576, 38241, 51814, 52584, 51475, 51412, 34157, 40, 52559, 51416, 52592, 52246, 74, 51849, 26351, 51456, 28537, 51241, 51465, 52176, 52063, 51809, 93, 46987, 51584, 52215, 185, 43305, 51135, 52177, 20575, 46999, 46997, 51568, 51625, 51843, 21935, 51835, 52190, 415, 51476, 641, 51614, 13561, 52601, 51367, 51169, 51134, 51654, 51386, 51137, 49, 78, 51632, 51243, 52049, 79, 51178, 31, 51409, 51986, 52, 51156, 52593, 51141, 51856, 51393, 19653, 51817, 51791, 52194, 51244, 329, 52058, 51823, 51836, 646, 51394, 51159, 51579, 51474, 51624, 54, 52591, 51837, 82, 434, 51171, 52581, 23147, 52518, 52241, 51417, 52179, 5431, 642, 34072, 52178, 46243, 46994, 39557, 52587, 52233, 51278, 51593, 51588, 83, 52008, 51590, 1202, 643, 38239, 52041, 52232, 52517, 42620, 52062, 52175, 52575, 51816, 52244, 51591, 102, 86, 51800, 47001] do
      try do
        %PanWeb.CategoryPodcast{podcast_id: podcast_id, category_id: 106}
        |> Repo.insert()
      rescue
        e in Ecto.ConstraintError -> e
      end
    end

    render(conn, PanWeb.PageFrontendView, "done.html")
  end
end
