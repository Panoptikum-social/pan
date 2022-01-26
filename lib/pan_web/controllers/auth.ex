defmodule PanWeb.Auth do
  import Plug.Conn
  import Bcrypt, only: [verify_pass: 2, no_user_verify: 0]
  import Pan.Parser.MyDateTime, only: [now: 0]
  alias Pan.Repo
  alias PanWeb.User

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)

    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      user = user_id && repo.get(PanWeb.User, user_id) ->
        put_current_user(conn, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> put_session(:admin, user.admin)
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

  def login_by_username_and_pass(conn, username, given_pass) do
    user = Repo.get_by(User, username: username) || Repo.get_by(User, email: username)

    cond do
      user && verify_pass(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}

      user ->
        {:error, :unauthorized, conn}

      true ->
        no_user_verify()
        {:error, :not_found, conn}
    end
  end

  def login_by_token(conn, token) do
    case Phoenix.Token.verify(PanWeb.Endpoint, "user", token, max_age: 60 * 5) do
      {:ok, user_id} ->
        user = Repo.get!(User, user_id)
        {:ok, login(conn, user)}

      {:error, :expired} ->
        {:error, :expired}

      {:error, :invalid} ->
        {:error, :invalid}

      _ ->
        no_user_verify()
        {:error, :not_found, conn}
    end
  end

  def grant_access_by_token(_conn, token) do
    case Phoenix.Token.verify(PanWeb.Endpoint, "persona", token, max_age: 60 * 60 * 48) do
      {:ok, persona_id} ->
        {:ok, String.to_integer(persona_id)}

      {:error, :expired} ->
        {:error, :expired}

      {:error, :invalid} ->
        {:error, :invalid}

      _ ->
        {:error, :invalid}
    end
  end

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  alias PanWeb.Router.Helpers

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> put_session(:desired_url, conn.request_path)
      |> redirect(to: Helpers.session_path(conn, :new))
      |> halt()
    end
  end

  def authenticate_pro(conn, _opts) do
    current_user = conn.assigns.current_user

    if current_user && current_user.pro_until != nil &&
         NaiveDateTime.compare(current_user.pro_until, now()) == :gt do
      conn
    else
      conn
      |> put_flash(:error, "You need to be logged in with a pro account to access that page.")
      |> put_session(:desired_url, conn.request_path)
      |> redirect(to: Helpers.session_path(conn, :new))
      |> halt()
    end
  end

  def authenticate_admin(conn, _opts) do
    current_user = conn.assigns.current_user
    if current_user && current_user.admin do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this page.")
      |> put_session(:desired_url, conn.request_path)
      |> redirect(to: Helpers.session_path(conn, :new))
      |> halt()
    end
  end

  def unset_cookie(conn, _opts) do
    # if not logged in yet or do not fill out a form, we earlier deleted the cookie
    # unfortunately, we cannot use this features any more, as we want to use urface and LiveView from the very start
    if conn.assigns.current_user ||
         conn.path_info == ["sessions", "new"] ||
         conn.path_info == ["sessions"] ||
         conn.path_info == ["forgot_password"] ||
         conn.path_info == ["users", "new"] ||
         conn.path_info == ["users"] do
      conn
    else
      configure_session(conn, drop: true)
    end
  end
end
