defmodule Pan.Auth do
  import Plug.Conn
  alias Pan.Repo
  alias Pan.User

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)
      user = user_id && repo.get(Pan.User, user_id) ->
        put_current_user(conn, user)
      true ->
        assign(conn, :current_user, nil)
    end
  end


  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end


  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end


  def logout(conn) do
    configure_session(conn, drop: true)
  end


  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  def login_by_username_and_pass(conn, username, given_pass) do
    user = Repo.get_by(User, username: username) || Repo.get_by(User, email: username)

    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      user ->
        {:error, :unauthorized, conn}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end


  def login_by_token(conn, token) do
    case Phoenix.Token.verify(Pan.Endpoint, "user", token, max_age: 60*5) do
      {:ok, user_id} ->
        user = Repo.get!(User, user_id)
        {:ok, login(conn, user)}
      {:error, :expired} ->
        {:error, :expired}
      {:error, :invalid} ->
        {:error, :invalid}
      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end


  import Phoenix.Controller
  alias Pan.Router.Helpers

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> redirect(to: Helpers.podcast_frontend_path(conn, :index))
      |> halt()
    end
  end


  def authenticate_admin(conn, opts) do
    authenticate_user(conn, opts)
    if conn.assigns.current_user.admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be admin to access this page.")
      |> redirect(to: Helpers.podcast_frontend_path(conn, :index))
      |> halt()
    end
  end
end
