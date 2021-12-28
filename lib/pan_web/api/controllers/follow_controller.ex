defmodule PanWeb.Api.FollowController do
  use PanWeb, :controller
  alias PanWeb.{Api.Helpers, Category, Follow, Persona, Podcast, Subscription, User}
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def show(conn, %{"id" => id}, _user) do
    follow =
      from(f in Follow,
        join: u in assoc(f, :follower),
        where: f.id == ^id and u.share_follows == true,
        limit: 1,
        preload: [:category, :follower, :user, :podcast, :persona]
      )
      |> Repo.all()

    if follow != [] do
      render(conn, "show.json-api",
        data: follow,
        opts: [include: "category,follower,user,podcast,persona"]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"persona_id" => persona_id}, user) do
    case Repo.get(Persona, persona_id) do
      %PanWeb.Persona{} ->
        {:ok, follow} =
          persona_id
          |> String.to_integer()
          |> Persona.follow(user.id)

        follow =
          follow
          |> Repo.preload([:category, :follower, :user, :podcast, :persona])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: follow, opts: [include: "persona"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"user_id" => user_id}, current_user) do
    case Repo.get(User, user_id) do
      %PanWeb.User{} ->
        {:ok, follow} =
          user_id
          |> String.to_integer()
          |> User.follow(current_user.id)

        follow =
          follow
          |> Repo.preload([:category, :follower, :user, :podcast, :persona])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: follow, opts: [include: "user"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    case Repo.get(Podcast, podcast_id) do
      %PanWeb.Podcast{} ->
        {:ok, follow} =
          podcast_id
          |> String.to_integer()
          |> Podcast.follow(user.id)

        follow =
          follow
          |> Repo.preload([:category, :follower, :user, :podcast, :persona])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: follow, opts: [include: "podcast"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def toggle(conn, %{"category_id" => category_id}, user) do
    case Repo.get(Category, category_id) do
      %PanWeb.Category{} ->
        {:ok, follow} =
          category_id
          |> String.to_integer()
          |> Category.follow(user.id)

        follow =
          follow
          |> Repo.preload([:category, :follower, :user, :podcast, :persona])
          |> mark_if_deleted()

        render(conn, "show.json-api", data: follow, opts: [include: "category"])

      nil ->
        Helpers.send_404(conn)
    end
  end

  def follow_all_subscribed_podcasts(conn, _params, user) do
    subscribed_podcast_ids =
      from(s in Subscription,
        where: s.user_id == ^user.id,
        select: s.podcast_id
      )
      |> Repo.all()

    followed_ids =
      from(f in Follow,
        where:
          f.follower_id == ^user.id and
            not is_nil(f.podcast_id),
        select: f.podcast_id
      )
      |> Repo.all()

    for id <- subscribed_podcast_ids do
      unless Enum.member?(followed_ids, id) do
        Podcast.follow(id, user.id)
      end
    end

    follows =
      from(f in Follow,
        where:
          f.follower_id == ^user.id and
            not is_nil(f.podcast_id),
        preload: [:category, :follower, :user, :podcast, :persona]
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: follows,
      opts: [include: "follower,podcast"]
    )
  end
end
