defmodule Pan.RecommendationFrontendController do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Episode
  alias Pan.Category
  alias Pan.Chapter
  alias Pan.Recommendation
  alias Pan.Subscription
  alias Pan.Message
  alias Pan.Language


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, params, _) do
    recommendations = from(p in Recommendation, order_by: [desc: :inserted_at],
                                                preload: [:user, :podcast, episode: :podcast,
                                                          chapter: [episode: :podcast]])
                      |> Repo.paginate(page: params[:page], page_size: 16)

    render(conn, "index.html", recommendations: recommendations)
  end


  def my_recommendations(conn,_params, user) do
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

    render(conn, "my_recommendations.html", podcast_recommendations: podcast_recommendations,
                                            unrecommended_podcasts: unrecommended_podcasts,
                                            changeset: changeset)
  end


  def random(conn, _params, _user) do
    podcast = Repo.all(Podcast)
               |> Enum.random
               |> Repo.preload(:categories)

    category = Repo.get(Category, List.first(podcast.categories).id)
               |> Repo.preload([:parent, :children,
                                [podcasts: :languages]])

    podcasts = from(l in Language, right_join: p in assoc(l, :podcasts),
                                   join: c in assoc(p, :categories),
                                   where: c.id == ^category.id,
                                   select: %{id: p.id,
                                             title: p.title,
                                             language_name: l.name,
                                             language_emoji: l.emoji})
                                   |> Repo.all()

    podcast = Repo.get(Podcast, podcast.id)
              |> Repo.preload([:episodes, :languages, :categories, :feeds, engagements: :persona])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, [chapters: :recommendations],
                               :contributors, :recommendations, [gigs: :persona]])

    changeset = Recommendation.changeset(%Recommendation{})

    render(conn, "random.html", category: category,
                                podcast: podcast,
                                episode: episode,
                                player: "podigee",
                                podcasts: podcasts,
                                changeset: changeset)
  end


  def create(conn, %{"recommendation" => recommendation_params}, user) do
    recommendation_params = Map.put(recommendation_params, "user_id", user.id)
    changeset = Recommendation.changeset(%Recommendation{}, recommendation_params)

    e =
    cond do
      podcast_id_param = recommendation_params["podcast_id"] ->
        podcast_id = String.to_integer(podcast_id_param)

        %Event{topic:      "podcasts",
               subtopic:   podcast_id_param,
               podcast_id: podcast_id,
               episode_id: nil,
               chapter_id: nil,
               notification_text: "Podcast <b>" <> Repo.get!(Podcast, podcast_id).title <> "</b>"}

      episode_id_param = recommendation_params["episode_id"] ->
        episode_id = String.to_integer(episode_id_param)
        episode = Repo.get!(Episode, episode_id)
                  |> Repo.preload(:podcast)

        %Event{topic: "podcasts",
               subtopic: Integer.to_string(episode.podcast.id),
               podcast_id: episode.podcast.id,
               episode_id: episode_id,
               chapter_id: nil,
               notification_text: "Episode <b>" <> episode.title <>
                                  "</b> from <b>" <> episode.podcast.title <> "</b>"}

      chapter_id_param = recommendation_params["chapter_id"] ->
        chapter_id = String.to_integer(chapter_id_param)
        chapter = Repo.get!(Chapter, chapter_id)
                  |> Repo.preload([episode: :podcast])

        %Event{topic:      "podcasts",
               subtopic:   Integer.to_string(chapter.episode.podcast.id),
               podcast_id: chapter.episode.podcast.id,
               episode_id: chapter.episode.id,
               chapter_id: chapter_id,
               notification_text: "Chapter <b>" <> chapter.title <> "</b> in <b>" <>
                                  chapter.episode.title <> "</b> from <b>" <>
                                  chapter.episode.podcast.title <> "</b>"}
    end

    e = %{e | current_user_id: user.id,
              type:            "success",
              event:           "recommend",
              content:         Pan.ViewHelpers.truncate("« recommended " <>
                                                        e.notification_text <> " » " <>
                                                        recommendation_params["comment"], 255)}

    Repo.insert(changeset)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    conn
    |> put_flash(:info, "Your recommendation has been added.")
    |> redirect_to_back
  end


  defp redirect_to_back(conn) do
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
