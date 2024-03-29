defmodule PanWeb.UserController do
  use PanWeb, :controller
  alias PanWeb.{Subscription, User, PageFrontendView}

  plug(:authenticate_user when action in [:index, :show])

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def unset_pro(conn, %{"id" => id}, _user) do
    Repo.get(User, id)
    |> User.changeset(%{pro_until: nil})
    |> Repo.update()

    conn
    |> put_flash(:info, "User pro_until date deleted.")
    |> redirect(to: user_frontend_path(conn, :index))
  end

  def forgot_password(conn, _params, _user) do
    render(conn, "forgot_password.html")
  end

  def request_login_link(conn, %{"user" => user_params}, _user) do
    changeset = User.request_login_changeset(%User{}, user_params)

    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        # we ignore unknown emails on purpose
        true

      user ->
        Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)
        |> Pan.Email.login_link_html_email(changeset.changes.email)
        |> Pan.Mailer.deliver()
    end

    render(conn, "login_link_sent.html")
  end

  def merge(conn, _params, _user) do
    render(conn, "merge.html")
  end

  def execute_merge(conn, %{"users" => %{"from" => from, "into" => into}}, _user) do
    from_id = String.to_integer(from)
    into_id = String.to_integer(into)

    from(c in PanWeb.Manifestation, where: c.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(f in PanWeb.FeedBacklog, where: f.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(f in PanWeb.Follow, where: f.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(f in PanWeb.Follow, where: f.follower_id == ^from_id)
    |> Repo.update_all(set: [follower_id: into_id])

    from(l in PanWeb.Like, where: l.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(l in PanWeb.Like, where: l.enjoyer_id == ^from_id)
    |> Repo.update_all(set: [enjoyer_id: into_id])

    from(o in PanWeb.Opml, where: o.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(s in PanWeb.Subscription, where: s.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    from(r in PanWeb.Recommendation, where: r.user_id == ^from_id)
    |> Repo.update_all(set: [user_id: into_id])

    Repo.get!(User, from_id)
    |> Repo.delete!()

    render(conn, "merge.html")
  end

  def push_subscriptions(conn, %{"user_id" => user_id, "category_id" => category_id}, _user) do
    # pushes all of a user's subscribed podcasts into a category (e.g. for a community)
    podcast_ids =
      from(s in Subscription,
        where: s.user_id == ^user_id,
        select: s.podcast_id
      )
      |> Repo.all()

    for podcast_id <- podcast_ids do
      PanWeb.CategoryPodcast.get_or_insert(String.to_integer(category_id), podcast_id)
    end

    conn
    |> put_view(PageFrontendView)
    |> render("done.html")
  end

  def edit_password(conn, %{"id" => id}, _user) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user)
    render(conn, "edit_password.html", user: user, changeset: changeset)
  end

  def update_password(conn, %{"id" => id, "user" => user_params}, _user) do
    user = Repo.get!(User, id)
    changeset = User.password_update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> redirect(to: databrowser_path(conn, :show, "user", user))

      {:error, changeset} ->
        render(conn, "edit_password.html", user: user, changeset: changeset)
    end
  end
end
