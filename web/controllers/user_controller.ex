defmodule Pan.UserController do
  use Pan.Web, :controller
  alias Pan.User

  plug :scrub_params, "user" when action in [:create, :update]
  plug :authenticate_user when action in [:index, :show]


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    users = Repo.all(Pan.User)
    render conn, "index.html", users: users
  end


  def show(conn, %{"id" => id}, _user) do
    user = Repo.get(Pan.User, id)
    render conn, "show.html", user: user
  end


  def new(conn, _params, _user) do
    changeset = User.changeset(%User{})
    render conn, "new.html", changeset: changeset
  end


  def create(conn, %{"user" => user_params}, _user) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> Pan.Auth.login(user)
        |> put_flash(:info, "Your account @#{user.name} has been created!")
        |> redirect(to: category_frontend_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def edit(conn, %{"id" => id}, _user) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end


  def update(conn, %{"id" => id, "user" => user_params}, _user) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
         conn
         |> put_flash(:info, "User updated successfully.")
         |> redirect(to: user_path(conn, :show, user))
      {:error, changeset} ->
         render(conn, "edit.html", user: user, changeset: changeset)
    end
  end


  def delete(conn, %{"id" => id}, _user) do
    user = Repo.get!(User, id)
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end


  def forgot_password(conn, _params, _user) do
    render(conn, "forgot_password.html")
  end


  def request_login_link(conn, %{"user" => user_params}, _user) do
    changeset = User.request_login_changeset(%User{}, user_params)

    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        true # we ignore unknown emails on purpose
      user ->
        Phoenix.Token.sign(Pan.Endpoint, "user", user.id)
        |> Pan.Email.login_link_html_email(changeset.changes.email)
        |> Pan.Mailer.deliver_now()
    end
    render(conn, "login_link_sent.html")
  end
end
