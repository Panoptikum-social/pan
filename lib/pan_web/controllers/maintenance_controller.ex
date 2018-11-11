defmodule PanWeb.MaintenanceController do
  use Pan.Web, :controller
  alias PanWeb.{Category, Delegation, Engagement, Episode, Feed,
                FeedBacklog, Follow, Gig, Language,
                Like, Manifestation, Opml, Persona, Podcast,
                Recommendation, Subscription, User}


  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.io/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2017/#{month}/#{day}/#{file}")
  end


  def update_podcast_counters(conn, _params) do
    Podcast.update_all_counters()

    render(conn, "done.html")
  end


  def sandbox(conn, _params) do
    render(conn, "sandbox.html")
  end


  def catch_up_thumbnailed(conn, _paar) do
    podcast_candidates =
      (from e in Podcast, where: is_nil(e.thumbnailed) and not is_nil(e.image_url),
                          limit: 1_000,
                          select: e.id)
    |> Repo.all()

    podcasts_missing_thumbnailed =
      (from e in Podcast, where: e.id in ^podcast_candidates,
                          left_join: i in assoc(e, :thumbnails),
                          where: not is_nil(i.podcast_id),
                          select: e.id)
      |> Repo.all()

    (from p in Podcast, where: p.id in ^podcasts_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    persona_candidates =
      (from e in Persona, where: is_nil(e.thumbnailed) and not is_nil(e.image_url),
                          limit: 1_000,
                          select: e.id)
    |> Repo.all()

    personas_missing_thumbnailed =
      (from e in Persona, where: e.id in ^persona_candidates,
                          left_join: i in assoc(e, :thumbnails),
                          where: not is_nil(i.persona_id),
                          select: e.id)
      |> Repo.all()

    (from p in Persona, where: p.id in ^personas_missing_thumbnailed)
    |> Repo.update_all(set: [thumbnailed: true])

    for _i <- 1..10 do
      episode_candidates =
        (from e in Episode, where: is_nil(e.thumbnailed) and not is_nil(e.image_url),
                            limit: 1_000,
                            select: e.id)
      |> Repo.all()

      episodes_missing_thumbnailed =
        (from e in Episode, where: e.id in ^episode_candidates,
                            left_join: i in assoc(e, :thumbnails),
                            where: not is_nil(i.episode_id),
                            select: e.id)
        |> Repo.all()

      (from e in Episode, where: e.id in ^episodes_missing_thumbnailed)
      |> Repo.update_all(set: [thumbnailed: true])
    end

    render(conn, "done.html")
  end


  def stats(conn, _params) do
    stale_podcasts =
      from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                is_false(p.update_paused) and
                                is_false(p.retired))
      |> Repo.aggregate(:count, :id)
      |> delimit_integer(" ")

    inactive_podcasts =
      from(p in Podcast, where: p.update_paused == true and is_false(p.retired))
      |> Repo.aggregate(:count, :id)

    retired_podcasts =
      from(p in Podcast, where: p.retired == true)
      |> Repo.aggregate(:count, :id)

    average_update_intervall =
      from(p in Podcast, where: is_false(p.update_paused) and is_false(p.retired))
      |> Repo.aggregate(:avg, :update_intervall)
      |> Decimal.round(2)

    total_podcasts = Repo.aggregate(Podcast, :count, :id)
                     |> delimit_integer(" ")

    feeds_without_headers = from(f in Feed, where: f.no_headers_available == ^true)
                            |> Repo.aggregate(:count, :id)

    feeds_with_etag = from(f in Feed, where: not is_nil(f.etag))
                      |> Repo.aggregate(:count, :id)

    feeds_with_last_modified = from(f in Feed, where: not is_nil(f.last_modified))
                      |> Repo.aggregate(:count, :id)


    total_episodes = Repo.aggregate(Podcast, :sum, :episodes_count)
                     |> delimit_integer(" ")

    unindexed_episodes = from(e in Episode, where: is_false(e.elastic))
                         |> Repo.aggregate(:count, :id)
                         |> delimit_integer(" ")

    podcasts_per_hour = Repo.aggregate(Podcast, :count, :id) - inactive_podcasts
                        |> Decimal.new()
                        |> Decimal.div(average_update_intervall)
                        |> Decimal.round()

    total_users = Repo.aggregate(User, :count, :id)
    total_gigs = Repo.aggregate(Gig, :count, :id)
                 |> delimit_integer(" ")
    total_engagements = Repo.aggregate(Engagement, :count, :id)
                        |> delimit_integer(" ")
    total_personas = Repo.aggregate(Persona, :count, :id)
                     |> delimit_integer(" ")
    total_subscriptions = Repo.aggregate(Subscription, :count, :id)
                          |> delimit_integer(" ")
    total_likes = Repo.aggregate(Like, :count, :id)
    total_recommendations = Repo.aggregate(Recommendation, :count, :id)
    total_categories = Repo.aggregate(Category, :count, :id)
    total_categorizations = Repo.aggregate("categories_podcasts", :count, :podcast_id)
                            |> delimit_integer(" ")
    total_languages = Repo.aggregate(Language, :count, :id)
    total_opmls = Repo.aggregate(Opml, :count, :id)
    total_feed_backlogs = Repo.aggregate(FeedBacklog, :count, :id)
    total_follows = Repo.aggregate(Follow, :count, :id)
    total_manifestations = Repo.aggregate(Manifestation, :count, :id)
    total_delegations = Repo.aggregate(Delegation, :count, :id)

    episodes_without_image =
      (from e in Episode, where: is_nil(e.thumbnailed) and not is_nil(e.image_url))
      |> Repo.aggregate(:count, :id)

    podcasts_without_image =
      (from p in Podcast, where: is_nil(p.thumbnailed) and not is_nil(p.image_url))
      |> Repo.aggregate(:count, :id)

    personas_without_image =
      (from p in Persona, where: is_nil(p.thumbnailed) and not is_nil(p.image_url))
      |> Repo.aggregate(:count, :id)

    render(conn, "stats.html", stale_podcasts: stale_podcasts,
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
                               episodes_without_image: episodes_without_image,
                               podcasts_without_image: podcasts_without_image,
                               personas_without_image: personas_without_image,
                               feeds_without_headers: feeds_without_headers,
                               feeds_with_etag: feeds_with_etag,
                               feeds_with_last_modified: feeds_with_last_modified)
  end

  defp delimit_integer(number, delimiter) do
    abs(number)
    |> Integer.to_charlist
    |> :lists.reverse
    |> delimit_integer(delimiter, [])
  end
  defp delimit_integer([a,b,c,d|tail], delimiter, acc) do
    delimit_integer([d|tail], delimiter, [delimiter,c,b,a|acc])
  end
  defp delimit_integer(list, _, acc) do
    :lists.reverse(list) ++ acc
  end
end
