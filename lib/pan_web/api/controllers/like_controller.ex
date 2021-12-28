defmodule PanWeb.Api.LikeController do
  use PanWeb, :controller

  alias PanWeb.{
    Api.Helpers,
    Category,
    Chapter,
    Episode,
    Like,
    Persona,
    Podcast,
    Subscription,
    User
  }

  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    like =
      from(l in Like,
        where: l.id == ^id,
        limit: 1,
        preload: [:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode]
      )
      |> Repo.all()

    if like != [] do
      render(conn, "show.json-api",
        data: like,
        opts: [include: "category,enjoyer,user,podcast,chapter,persona,episode"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"persona_id" => persona_id}, user) do
    case Repo.get(Persona, persona_id) do
      %PanWeb.Persona{} ->
        {:ok, like} =
          persona_id
          |> String.to_integer()
          |> Persona.like(user.id)

        like =
          like
          |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: like, opts: [include: "persona"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"user_id" => user_id}, current_user) do
    case Repo.get(User, user_id) do
      %PanWeb.User{} ->
        {:ok, like} =
          user_id
          |> String.to_integer()
          |> User.like(current_user.id)

        like =
          like
          |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: like, opts: [include: "user"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"chapter_id" => chapter_id}, user) do
    case Repo.get(Chapter, chapter_id) do
      %PanWeb.Chapter{} ->
        {:ok, like} =
          chapter_id
          |> String.to_integer()
          |> Chapter.like(user.id)

        like =
          like
          |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: like, opts: [include: "chapter"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"episode_id" => episode_id}, user) do
    case Repo.get(Episode, episode_id) do
      %PanWeb.Episode{} ->
        {:ok, like} =
          episode_id
          |> String.to_integer()
          |> Episode.like(user.id)

        like =
          like
          |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: like, opts: [include: "episode"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    case Repo.get(Podcast, podcast_id) do
      %PanWeb.Podcast{} ->
        {:ok, like} =
          podcast_id
          |> String.to_integer()
          |> Podcast.like(user.id)

        like =
          like
          |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: like, opts: [include: "podcast"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"category_id" => category_id}, user) do
    case Repo.get(Category, category_id) do
      %PanWeb.Category{} ->
        {:ok, like} =
          category_id
          |> String.to_integer()
          |> Category.like(user.id)

        render(conn, "show.json-api", data: like, opts: [include: "category"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def like_all_subscribed_podcasts(conn, _params, user) do
    subscribed_podcast_ids =
      Repo.all(
        from(s in Subscription,
          where: s.user_id == ^user.id,
          select: s.podcast_id
        )
      )

    liked_ids =
      from(l in Like,
        where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
        select: l.podcast_id
      )
      |> Repo.all()

    for id <- subscribed_podcast_ids do
      unless Enum.member?(liked_ids, id) do
        Podcast.like(id, user.id)
      end
    end

    likes =
      from(l in Like,
        where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
        preload: [:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode]
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: likes,
      opts: [include: "podcast,user"]
    )
  end
end
