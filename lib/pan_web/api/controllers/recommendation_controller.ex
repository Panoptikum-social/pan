defmodule PanWeb.Api.RecommendationController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Category, Episode, Podcast, Recommendation}
  alias Pan.Parser.Helpers, as: H

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, params, _user) do
    page =
      if is_map(params["page"]) do
        get_in(params, ["page", "number"]) || "1"
      else
        "1"
      end
      |> String.to_integer()

    size =
      if is_map(params["page"]) do
        get_in(params, ["page", "size"]) || "10"
      else
        "10"
      end
      |> String.to_integer()
      |> min(1000)

    offset = (page - 1) * size

    total = Repo.aggregate(Recommendation, :count, :id)
    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_episode_url(:index)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    recommendations =
      from(e in Recommendation,
        order_by: [desc: :inserted_at],
        preload: [:podcast, :episode, :chapter, :user],
        limit: ^size,
        offset: ^offset
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: recommendations,
      opts: [page: links, include: "podcast,episode,chapter,user"]
    )
  end

  def show(conn, %{"id" => id}, _user) do
    recommendation =
      Repo.get(Recommendation, id)
      |> Repo.preload([:podcast, :episode, :chapter, :user])

    if recommendation do
      render(conn, "show.json-api",
        data: recommendation,
        opts: [include: "podcast,episode,chapter,user"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def random(conn, _params, _user) do
    podcast =
      from(p in Podcast,
        order_by: fragment("RANDOM()"),
        limit: 1,
        preload: [:episodes, :languages, :categories, :feeds, engagements: :persona]
      )
      |> Repo.one()

    category =
      Repo.get(Category, List.first(podcast.categories).id)
      |> Repo.preload([:parent, :children, :podcasts])

    episode = Enum.random(podcast.episodes)

    episode =
      Repo.get(Episode, episode.id)
      |> Repo.preload([
        :podcast,
        :enclosures,
        [chapters: :recommendations],
        :contributors,
        :recommendations,
        [gigs: :persona]
      ])

    recommendation =
      %Recommendation{podcast_id: podcast.id, episode_id: episode.id, id: "random"}
      |> struct(
        podcast: podcast,
        episode: episode,
        category: category,
        chapter: nil,
        user: %PanWeb.User{id: 1, name: "Fortuna"}
      )

    render(conn, "show.json-api",
      data: recommendation,
      opts: [include: "podcast,episode,category"]
    )
  end

  def my(conn, _params, user) do
    recommendations =
      Repo.all(
        from(r in Recommendation,
          where:
            r.user_id == ^user.id and
              not is_nil(r.podcast_id) and
              is_nil(r.episode_id) and
              is_nil(r.chapter_id),
          order_by: [desc: :inserted_at],
          preload: [:podcast, :user, :chapter, :episode]
        )
      )

    render(conn, "index.json-api",
      data: recommendations,
      opts: [include: "podcast"]
    )
  end

  def create(conn, %{"podcast_id" => podcast_id, "comment" => comment} = _params, user) do
    comment = H.to_255(comment)
    podcast_id = String.to_integer(podcast_id)

    case Repo.get(Podcast, podcast_id) do
      %PanWeb.Podcast{} ->
        {:ok, recommendation} =
          %Recommendation{podcast_id: podcast_id, comment: comment, user_id: user.id}
          |> Recommendation.changeset()
          |> Repo.insert()

        recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

        render(conn, "show.json-api",
          data: recommendation,
          opts: [include: "podcast,user"]
        )

      nil ->
        Helpers.send_404(conn)
    end
  end

  def create(conn, %{"episode_id" => episode_id, "comment" => comment}, user) do
    comment = H.to_255(comment)
    episode_id = String.to_integer(episode_id)

    {:ok, recommendation} =
      %Recommendation{episode_id: episode_id, comment: comment, user_id: user.id}
      |> Recommendation.changeset()
      |> Repo.insert()

    recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

    render(conn, "show.json-api",
      data: recommendation,
      opts: [include: "episode,user"]
    )
  end

  def create(conn, %{"chapter_id" => chapter_id, "comment" => comment}, user) do
    comment = H.to_255(comment)
    chapter_id = String.to_integer(chapter_id)

    {:ok, recommendation} =
      %Recommendation{chapter_id: chapter_id, comment: comment, user_id: user.id}
      |> Recommendation.changeset()
      |> Repo.insert()

    recommendation = Repo.preload(recommendation, [:podcast, :episode, :chapter, :user])

    render(conn, "show.json-api",
      data: recommendation,
      opts: [include: "chapter,user"]
    )
  end
end
