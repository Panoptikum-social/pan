defmodule Pan.RecommendationFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category
  alias Pan.Chapter
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
                                                                 order_by: [desc: :inserted_at],
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
    podcast = Repo.all(Podcast)
               |> Enum.random
               |> Repo.preload(:categories)

    category = Repo.get(Category, List.first(podcast.categories).id)
               |> Repo.preload([:parent, :children, :podcasts])

    podcast = Repo.get(Podcast, podcast.id)
              |> Repo.preload([:episodes, :languages, :owner, :categories, :feeds])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, [chapters: :recommendations],
                               :contributors, :recommendations])

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

    cond do
      podcast_id_param = recommendation_params["podcast_id"] ->
        podcast_id = String.to_integer(podcast_id_param)
        episode_id = nil
        topic = "podcasts"
        subtopic = podcast_id_param
        notification_text = "Podcast <b>" <> Repo.get!(Podcast, podcast_id).title <> "</b>"
      episode_id_param = recommendation_params["episode_id"] ->
        episode_id = String.to_integer(episode_id_param)
        episode = Repo.get!(Episode, episode_id)
                  |> Repo.preload(:podcast)
        podcast_id = episode.podcast.id
        topic = "podcasts"
        subtopic = Integer.to_string(episode.podcast.id)
        notification_text = "Episode <b>" <> episode.title <> "</b> from <b>" <> episode.podcast.title <> "</b>"
      chapter_id_param = recommendation_params["chapter_id"] ->
        chapter_id = String.to_integer(chapter_id_param)
        chapter = Repo.get!(Chapter, chapter_id)
                  |> Repo.preload([episode: :podcast])
        episode_id = chapter.episode.id
        podcast_id = chapter.episode.podcast.id
        topic = "podcasts"
        subtopic = Integer.to_string(chapter.episode.podcast.id)
        notification_text = "Chapter <b>" <> chapter.title <> "</b> in <b>" <>
                            chapter.episode.title <> "</b> from <b>" <>
                            chapter.episode.podcast.title <> "</b>"
    end

    comment = recommendation_params["comment"]

    e = %Event{
      topic:           topic,
      subtopic:        subtopic,
      current_user_id: user.id,
      podcast_id:      podcast_id,
      episode_id:      episode_id,
      chapter_id:      chapter_id,
      type:            "success",
      event:           "recommend",
      content:         comment
    }
    e = %{e | content: "« recommended " <>
                       notification_text <> " » " <> comment }

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
