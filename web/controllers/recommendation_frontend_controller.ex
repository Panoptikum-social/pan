defmodule Pan.RecommendationFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category
  alias Pan.Recommendation
  alias Pan.Subscription
  alias Pan.Message


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn,_params, user) do
    podcast_recommendations = Repo.all(from r in Recommendation, where: r.user_id == ^user.id and
                                                                        not is_nil(r.podcast_id) and
                                                                        is_nil(r.episode_id) and
                                                                        is_nil(r.chapter_id),
                                                                 preload: :podcast)

    subscribed_podcast_ids = Repo.all(from s in Subscription, where: s.user_id == ^user.id,
                                                              select: s.podcast_id)
    recommended_podcast_ids = Enum.map(podcast_recommendations, fn(recommendation) -> recommendation.podcast_id end)
    unrecommonded_podcast_ids = Enum.filter(subscribed_podcast_ids, fn(id) ->
      not Enum.member?(recommended_podcast_ids, id)
    end)
    unrecommended_podcasts = Repo.all(from p in Podcast, where: p.id in ^unrecommonded_podcast_ids)

    changeset = Recommendation.changeset(%Recommendation{})

    render(conn, "index.html", podcast_recommendations: podcast_recommendations,
                               unrecommended_podcasts: unrecommended_podcasts,
                               changeset: changeset)
  end


  def random(conn, _params, _user) do
    category = Repo.all(Category)
               |> Enum.random

    category = Repo.get(Category, category.id)
               |> Repo.preload([:parent, :children, :podcasts])

    podcast = Enum.random(category.podcasts)
    podcast = Repo.get(Podcast, podcast.id)
              |> Repo.preload([:episodes, :languages, :owner, :categories, :feeds])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, :chapters, :contributors])

    changeset = Recommendation.changeset(%Recommendation{})

    render(conn, "random.html", category: category,
                                podcast: podcast,
                                episode: episode,
                                player: "podigee",
                                changeset: changeset)
  end


  def create(conn, %{"recommendation" => recommendation_params}, user) do
    recommendation_params = Map.put(recommendation_params, "user_id", user.id)
    changeset = Recommendation.changeset(%Recommendation{}, recommendation_params)
    podcast_id = String.to_integer(recommendation_params["podcast_id"])
    comment = recommendation_params["comment"]

    e = %Event{
      topic:           "podcasts",
      subtopic:        recommendation_params["podcast_id"],
      current_user_id: user.id,
      podcast_id:      podcast_id,
      type:            "success",
      event:           "recommend",
      content:         comment
    }
    e = %{e | content: "« recommended <b>" <>
                       Repo.get!(Podcast, podcast_id).title <> " »</b> " <> comment }

    Repo.insert(changeset)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    conn
    |> put_flash(:info, "Your recommendation has been added.")
    |> redirect_to_back
  end


  defp redirect_to_back( conn) do
    path =
      conn
      |> Plug.Conn.get_req_header("referer")
      |> List.first
      |> URI.parse
      |> Map.get(:path)

    conn
    |> assign(:refer_path, path)
    |> redirect(to: path)
  end
end
