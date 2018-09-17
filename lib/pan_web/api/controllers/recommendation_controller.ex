defmodule PanWeb.Api.RecommendationController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Category, Chapter, Episode, Message, Podcast, Recommendation}
  alias Pan.Parser.Helpers , as: H

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, params, _user) do
    page = Map.get(params, "page", %{})
           |> Map.get("number", "1")
           |> String.to_integer
    size = Map.get(params, "page", %{})
           |> Map.get("size", "10")
           |> String.to_integer
           |> min(1000)
    offset = (page - 1) * size

    total = Repo.aggregate(Recommendation, :count, :id)
    total_pages = div(total - 1, size) + 1

    links = conn
    |> api_episode_url(:index)
    |> Helpers.pagination_links({page, size, total_pages}, conn)

    recommendations = from(e in Recommendation, order_by: [desc: :inserted_at],
                                                preload: [:podcast, :episode, :chapter, :user],
                                                limit: ^size,
                                                offset: ^offset)
               |> Repo.all()

    render conn, "index.json-api", data: recommendations,
                                   opts: [page: links,
                                          include: "podcast,episode,chapter,user"]
  end


  def show(conn, %{"id" => id}, _user) do
    recommendation = Repo.get(Recommendation, id)
                     |> Repo.preload([:podcast, :episode, :chapter, :user])

    if recommendation do
      render conn, "show.json-api", data: recommendation,
                                    opts: [include: "podcast,episode,chapter,user"]
    else
      Helpers.send_404(conn)
    end
  end


  def random(conn, _params, _user) do
    podcast = from(p in Podcast, order_by: fragment("RANDOM()"),
                                 limit: 1,
                                 preload: [:episodes, :languages, :categories, :feeds, engagements: :persona])
              |> Repo.one()

    category = Repo.get(Category, hd(podcast.categories).id)
               |> Repo.preload([:parent, :children, :podcasts])

    episode = Enum.random(podcast.episodes)
    episode = Repo.get(Episode, episode.id)
              |> Repo.preload([:podcast, :enclosures, [chapters: :recommendations],
                               :contributors, :recommendations, [gigs: :persona]])

    recommendation = %Recommendation{podcast_id: podcast.id, episode_id: episode.id, id: "random"}
                     |> struct(podcast: podcast,
                               episode: episode,
                               category: category,
                               chapter: {},
                               user: %PanWeb.User{id: 1, name: "Fortuna"})

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "podcast,episode,category"]

  end


  def my(conn, _params, user) do
    recommendations = Repo.all(from r in Recommendation, where: r.user_id == ^user.id and
                                                                not is_nil(r.podcast_id) and
                                                                is_nil(r.episode_id) and
                                                                is_nil(r.chapter_id),
                                                         order_by: [desc: :inserted_at],
                                                         preload: [:podcast, :user, :chapter, :episode])

    render conn, "index.json-api", data: recommendations,
                                   opts: [include: "podcast"]
  end


  def create(conn, %{"podcast_id" => podcast_id, "comment" => comment} = params, user) do
    comment = H.to_255(comment)
    podcast_id = String.to_integer(podcast_id)

    with %PanWeb.Podcast{} <- podcast = Repo.get(Podcast, podcast_id) do
      podcast_title = podcast.title
      notification_text = "Podcast <b> #{podcast_title}</b>"

      {:ok, recommendation} = %Recommendation{podcast_id: podcast_id,
                                              comment: comment,
                                              user_id: user.id}
                              |> Recommendation.changeset()
                              |> Repo.insert()

      recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

      e = %Event{topic: "podcasts",
                 subtopic: params["podcast_id"],
                 podcast_id: podcast_id,
                 episode_id: nil,
                 chapter_id: nil,
                 notification_text: notification_text,
                 current_user_id: user.id,
                 type: "success",
                 event: "recommend",
                 content: H.to_255("« recommended #{notification_text} » #{comment}")}

      Message.persist_event(e)
      Event.notify_subscribers(e)

      render conn, "show.json-api", data: recommendation,
                                    opts: [include: "podcast,user"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def create(conn, %{"episode_id" => episode_id, "comment" => comment}, user) do
    comment = H.to_255(comment)
    episode_id = String.to_integer(episode_id)
    episode = Repo.get!(Episode, episode_id)
              |> Repo.preload(:podcast)
    notification_text = "Episode <b>#{episode.title}</b> from <b>#{episode.podcast.title}</b>"

    {:ok, recommendation} = %Recommendation{episode_id: episode_id,
                                            comment: comment,
                                            user_id: user.id}
                            |> Recommendation.changeset()
                            |> Repo.insert()

    recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

    e = %Event{topic: "podcasts",
               subtopic: Integer.to_string(episode.podcast.id),
               podcast_id: episode.podcast.id,
               episode_id: episode_id,
               chapter_id: nil,
               notification_text: notification_text,
               current_user_id: user.id,
               type: "success",
               event: "recommend",
               content: H.to_255("« recommended #{notification_text} » #{comment}")}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "episode,user"]
  end


  def create(conn, %{"chapter_id" => chapter_id, "comment" => comment}, user) do
    comment = H.to_255(comment)
    chapter_id = String.to_integer(chapter_id)
    chapter = Repo.get!(Chapter, chapter_id)
              |> Repo.preload([episode: :podcast])
    notification_text = "Chapter <b>" <> chapter.title <> "</b> in <b>" <>
                        chapter.episode.title <> "</b> from <b>" <>
                        chapter.episode.podcast.title <> "</b>"

    {:ok, recommendation} = %Recommendation{chapter_id: chapter_id,
                                            comment: comment,
                                            user_id: user.id}
                            |> Recommendation.changeset()
                            |> Repo.insert()

    recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

    e = %Event{topic: "podcasts",
               subtopic: Integer.to_string(chapter.episode.podcast.id),
               podcast_id: chapter.episode.podcast.id,
               episode_id: chapter.episode.id,
               chapter_id: chapter_id,
               notification_text: notification_text,
               current_user_id: user.id,
               type: "success",
               event: "recommend",
               content: H.to_255("« recommended #{notification_text} » #{comment}")}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: recommendation,
                                  opts: [include: "chapter,user"]
  end
end
