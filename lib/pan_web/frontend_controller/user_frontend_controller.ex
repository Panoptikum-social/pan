defmodule PanWeb.UserFrontendController do
  use PanWeb, :controller
  alias PanWeb.{CategoryPodcast, Follow, Like, Persona, Podcast, Subscription, User}
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  plug(:scrub_params, "user" when action in [:create, :update])

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, _user) do
    users =
      Repo.all(
        from(u in User,
          order_by: :name,
          where: not u.admin
        )
      )

    render(conn, "index.html", users: users)
  end

  def edit(conn, _params, user) do
    changeset = User.changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}, user) do
    changeset = User.self_change_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: user_frontend_path(conn, :my_profile))

      {:error, changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def edit_password(conn, _params, user) do
    changeset = User.changeset(user)
    render(conn, "edit_password.html", user: user, changeset: changeset)
  end

  def update_password(conn, %{"user" => user_params}, user) do
    changeset = User.password_update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: user_frontend_path(conn, :my_profile))

      {:error, changeset} ->
        render(conn, "edit_password.html", user: user, changeset: changeset)
    end
  end

  def my_data(conn, _params, user) do
    user =
      Repo.get!(User, user.id)
      |> Repo.preload([
        :user_personas,
        :personas,
        :invoices,
        :podcasts_i_subscribed,
        :opmls,
        :users_i_like,
        :podcasts_i_follow,
        :categories_i_like,
        :categories_i_follow,
        :podcasts_i_like,
        :users_i_follow,
        :episodes_i_like,
        :personas_i_follow,
        :personas_i_like,
        [chapters_i_like: :episode],
        [recommendations: [:podcast, :episode, :chapter]]
      ])

    render(conn, "my_data.html", user: user)
  end

  def my_profile(conn, _params, user) do
    user =
      Repo.get!(User, user.id)
      |> Repo.preload(:user_personas)

    Persona.create_user_persona(user)

    user =
      Repo.preload(user, :invoices)
      |> Repo.preload(
        personas:
          from(Persona,
            order_by: :name,
            preload: [:delegates, :redirect, :thumbnails]
          )
      )

    render(conn, "my_profile.html", user: user)
  end

  def my_podcasts(conn, _params, user) do
    user =
      Repo.get(User, user.id)
      |> Repo.preload(podcasts_i_subscribed: from(p in Podcast, order_by: p.title))
      |> Repo.preload(podcasts_i_follow: from(p in Podcast, order_by: p.title))

    podcast_ids =
      from(l in Like,
        where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
        select: l.podcast_id
      )
      |> Repo.all()

    podcasts_i_like =
      from(p in Podcast,
        where: p.id in ^podcast_ids,
        order_by: :title
      )
      |> Repo.all()

    podcasts_subscribed_ids =
      from(s in Subscription,
        where: s.user_id == ^user.id,
        select: s.podcast_id
      )
      |> Repo.all()

    other_subscriber_ids =
      from(s in Subscription,
        where: s.podcast_id in ^podcasts_subscribed_ids,
        select: s.user_id
      )
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(user.id)

    recommendations =
      from(s in Subscription,
        join: p in assoc(s, :podcast),
        where:
          s.user_id in ^other_subscriber_ids and
            s.podcast_id not in ^podcasts_subscribed_ids,
        group_by: p.id,
        select: [count(s.podcast_id), p.id, p.title],
        order_by: [desc: count(s.podcast_id)],
        limit: 10
      )
      |> Repo.all()

    users_also_liking =
      from(l in Like,
        where: l.podcast_id in ^podcast_ids,
        select: l.enjoyer_id
      )
      |> Repo.all()
      |> Enum.uniq()
      |> List.delete(user.id)

    also_liked =
      from(l in Like,
        join: p in assoc(l, :podcast),
        where: l.enjoyer_id in ^users_also_liking and l.podcast_id not in ^podcast_ids,
        group_by: p.id,
        select: [count(l.podcast_id), p.id, p.title],
        order_by: [desc: count(l.podcast_id)],
        limit: 10
      )
      |> Repo.all()

    categories =
      from(r in CategoryPodcast,
        join: c in assoc(r, :category),
        where: r.podcast_id in ^podcasts_subscribed_ids,
        group_by: c.id,
        select: [count(r.category_id), c.id, c.title],
        order_by: [desc: count(r.category_id)],
        limit: 10
      )
      |> Repo.all()

    render(conn, "my_podcasts.html",
      user: user,
      podcasts_i_like: podcasts_i_like,
      recommendations: recommendations,
      also_liked: also_liked,
      categories: categories
    )
  end

  def like_all_subscribed(conn, _params, user) do
    subscribed_podcast_ids =
      from(s in Subscription,
        where: s.user_id == ^user.id,
        select: s.podcast_id
      )
      |> Repo.all()

    liked_ids =
      Repo.all(
        from(l in Like,
          where: l.enjoyer_id == ^user.id and not is_nil(l.podcast_id),
          select: l.podcast_id
        )
      )

    for id <- subscribed_podcast_ids do
      unless Enum.member?(liked_ids, id) do
        Podcast.like(id, user.id)
      end
    end

    conn
    |> put_flash(:info, "Liked all podcasts you had subscribed to.")
    |> redirect(to: user_frontend_path(conn, :my_podcasts))
  end

  def follow_all_subscribed(conn, _params, user) do
    subscribed_podcast_ids =
      Repo.all(
        from(s in Subscription,
          where: s.user_id == ^user.id,
          select: s.podcast_id
        )
      )

    followed_ids =
      Repo.all(
        from(f in Follow,
          where:
            f.follower_id == ^user.id and
              not is_nil(f.podcast_id),
          select: f.podcast_id
        )
      )

    for id <- subscribed_podcast_ids do
      unless Enum.member?(followed_ids, id) do
        Podcast.follow(id, user.id)
      end
    end

    conn
    |> put_flash(:info, "Followed all podcasts you had subscribed to.")
    |> redirect(to: user_frontend_path(conn, :my_podcasts))
  end

  def go_pro(conn, _params, user) do
    unless user.pro_until do
      payment_reference = "pan-#{user.id}-" <> Calendar.strftime(now(), "%x")

      User.changeset(user, %{
        pro_until: time_shift(now(), days: 30),
        payment_reference: payment_reference,
        billing_address: user.name
      })
      |> Repo.update()
    end

    conn
    |> put_flash(:info, "You are now a Panoptikum pro user!")
    |> redirect(to: user_frontend_path(conn, :my_profile))
  end

  def payment_info(conn, _params, user) do
    render(conn, "payment_info.html", user: user)
  end

  def delete_my_account(conn, _params, user) do
    Repo.get!(User, user.id)
    |> Repo.delete!()

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: "/")
  end
end
