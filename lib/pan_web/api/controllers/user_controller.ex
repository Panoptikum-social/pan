defmodule PanWeb.Api.UserController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Api.Helpers, Api.MyUserView, User}

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

    total =
      from(u in User, where: not u.admin)
      |> Repo.aggregate(:count)

    total_pages = div(total - 1, size) + 1

    links =
      conn
      |> api_user_url(:index)
      |> Helpers.pagination_links({page, size, total_pages}, conn)

    users =
      from(u in User,
        order_by: :name,
        limit: ^size,
        offset: ^offset,
        where: not u.admin
      )
      |> Repo.all()

    render(conn, "index.json-api",
      data: users,
      opts: [page: links]
    )
  end

  def show(conn, %{"id" => id}, _user) do
    user =
      Repo.get(User, id)
      |> Repo.preload([:categories_i_like, :users_i_like])

    include_string = "categories_i_like,users_i_like"

    {user, include_string} =
      if user && user.share_subscriptions do
        {Repo.preload(user, :podcasts_i_subscribed), include_string <> ",podcasts_i_subscribed"}
      else
        {user, include_string}
      end

    {user, include_string} =
      if user && user.share_follows do
        {Repo.preload(user, :podcasts_i_follow), include_string <> ",podcasts_i_follow"}
      else
        {user, include_string}
      end

    if user do
      render(conn, "show.json-api",
        data: user,
        opts: [include: include_string]
      )
    else
      Helpers.send_404(conn)
    end
  end

  def my(conn, _params, user) do
    user =
      Repo.get(User, user.id)
      |> Repo.preload(:personas)

    conn
    |> put_view(MyUserView)
    |> render("show.json-api",
      data: user,
      opts: [include: "personas"]
    )
  end

  def update_password(conn, params, user) do
    changeset = User.password_update_changeset(user, params)

    case Repo.update(changeset) do
      {:ok, user} ->
        user = Repo.preload(user, :personas)

        conn
        |> put_view(MyUserApiView)
        |> render("show.json-api",
          data: user,
          opts: [include: "personas"]
        )

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render(:errors, data: changeset)
    end
  end

  def update_user(conn, params, user) do
    changeset = User.self_change_changeset(user, params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        user = Repo.preload(user, :personas)

        conn
        |> put_view(MyUserView)
        |> render("show.json-api",
          data: user,
          opts: [include: "personas"]
        )

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render(:errors, data: changeset)
    end
  end

  def create(conn, params, _user) do
    changeset = User.registration_changeset(%User{}, params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        Phoenix.Token.sign(PanWeb.Endpoint, "user", user.id)
        |> Pan.Email.email_confirmation_link_html_email(user.email)
        |> Pan.Mailer.deliver()

        user = Repo.preload(user, :personas)

        conn
        |> put_view(MyUserView)
        |> render("show.json-api",
          data: user,
          opts: [include: "personas"]
        )

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> render(:errors, data: changeset)
    end
  end
end
