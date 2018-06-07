defmodule PanWeb.MaintenanceController do
  use Pan.Web, :controller
  alias PanWeb.{Episode, Podcast}

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.io/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2017/#{month}/#{day}/#{file}")
  end


  def fix(conn, _params) do
    render(conn, "done.html")
  end


  def update_podcast_counters(conn, _params) do
    Podcast.update_all_counters()

    render(conn, "done.html")
  end


  def sandbox(conn, _params) do
    render(conn, "sandbox.html")
  end


  def stats(conn, _params) do
    stale_podcasts =
      from(p in Podcast, where: p.next_update <= ^Timex.now() and
                                (is_nil(p.update_paused) or p.update_paused == false) and
                                (is_nil(p.retired) or p.retired == false))
      |> Repo.aggregate(:count, :id)
      |> delimit_integer(" ")

    inactive_podcasts =
      from(p in Podcast, where: (p.update_paused == true) and
                                (is_nil(p.retired) or p.retired == false))
      |> Repo.aggregate(:count, :id)

    retired_podcasts =
      from(p in Podcast, where: p.retired == true)
      |> Repo.aggregate(:count, :id)

    average_update_intervall =
      from(p in Podcast, where: (is_nil(p.update_paused) or p.update_paused == false) and
                                (is_nil(p.retired) or p.retired == false))
      |> Repo.aggregate(:avg, :update_intervall)
      |> Decimal.round(2)

    total_podcasts = Repo.aggregate(Podcast, :count, :id)
                     |> delimit_integer(" ")


    total_episodes = Repo.aggregate(PanWeb.Podcast, :sum, :episodes_count)
                     |> delimit_integer(" ")

    unindexed_episodes =
      from(p in Episode, where: (is_nil(p.elastic) or p.elastic == false))
      |> Repo.aggregate(:count, :id)
      |> delimit_integer(" ")

    podcasts_per_hour = Repo.aggregate(Podcast, :count, :id) - inactive_podcasts
                        |> Decimal.new()
                        |> Decimal.div(average_update_intervall)
                        |> Decimal.round()


    total_users = Repo.aggregate(PanWeb.User, :count, :id)
    total_gigs = Repo.aggregate(PanWeb.Gig, :count, :id)
                 |> delimit_integer(" ")
    total_engagements = Repo.aggregate(PanWeb.Engagement, :count, :id)
                        |> delimit_integer(" ")
    total_personas = Repo.aggregate(PanWeb.Persona, :count, :id)
                     |> delimit_integer(" ")
    total_subscriptions = Repo.aggregate(PanWeb.Subscription, :count, :id)
                          |> delimit_integer(" ")
    total_likes = Repo.aggregate(PanWeb.Like, :count, :id)
    total_recommendations = Repo.aggregate(PanWeb.Recommendation, :count, :id)
    total_categories = Repo.aggregate(PanWeb.Category, :count, :id)
    total_categorizations = Repo.aggregate("categories_podcasts", :count, :podcast_id)
                            |> delimit_integer(" ")
    total_languages = Repo.aggregate(PanWeb.Language, :count, :id)
    total_opmls = Repo.aggregate(PanWeb.Opml, :count, :id)
    total_feed_backlogs = Repo.aggregate(PanWeb.FeedBacklog, :count, :id)
    total_follows = Repo.aggregate(PanWeb.Follow, :count, :id)
    total_manifestations = Repo.aggregate(PanWeb.Manifestation, :count, :id)
    total_delegations = Repo.aggregate(PanWeb.Delegation, :count, :id)

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
                               unindexed_episodes: unindexed_episodes)

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
