defmodule PanWeb.Auth do
  import Plug.Conn
  import Bcrypt, only: [verify_pass: 2, no_user_verify: 0]
  alias Pan.Repo
  alias PanWeb.User

  # "Remember me for 30 days" — the regular session cookie has no max_age,
  # so it's a browser session cookie: browsers are free to (and often do,
  # especially closing a standalone-mode installed PWA window) drop it
  # without waiting for the whole browser to quit. This is a deliberately
  # separate, opt-in cookie rather than changing the session cookie itself,
  # so the default (no persistent login) is unaffected.
  @remember_me_cookie "_pan_remember_me"
  @remember_me_max_age 60 * 60 * 24 * 30

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    conn = fetch_cookies(conn)
    user_id = get_session(conn, :user_id)

    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      user = user_id && repo.get(PanWeb.User, user_id) ->
        put_current_user(conn, user)

      user = remembered_user(conn, repo) ->
        # Re-establishes a full session (see login/2) so subsequent
        # requests take the fast session-lookup path above instead of
        # re-verifying the remember-me cookie every time.
        login(conn, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  defp remembered_user(conn, repo) do
    with token when is_binary(token) <- conn.cookies[@remember_me_cookie],
         {:ok, user_id} <-
           Phoenix.Token.verify(conn, "remember_me", token, max_age: @remember_me_max_age) do
      repo.get(PanWeb.User, user_id)
    else
      _ -> nil
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> put_session(:admin, user.admin)
    |> configure_session(renew: true)
  end

  @doc """
  Sets the "remember me" cookie so `call/2` can silently re-establish a
  session after the regular session cookie is gone — call explicitly, only
  when the user opted in (it's independent of login/2 on purpose: every
  login path — password, email link — shouldn't set this unless asked).
  """
  def remember_me(conn, user) do
    token = Phoenix.Token.sign(conn, "remember_me", user.id)

    put_resp_cookie(conn, @remember_me_cookie, token,
      max_age: @remember_me_max_age,
      http_only: true
    )
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

  def logout(conn) do
    conn
    |> configure_session(drop: true)
    |> delete_resp_cookie(@remember_me_cookie)
  end

  def login_by_username_and_pass(conn, username, given_pass, remember_me? \\ false) do
    user = Repo.get_by(User, username: username) || Repo.get_by(User, email: username)

    cond do
      user && verify_pass(given_pass, user.password_hash) ->
        conn = login(conn, user)
        conn = if remember_me?, do: remember_me(conn, user), else: conn
        {:ok, conn}

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

  def authenticate_moderator(conn, _opts) do
    current_user = conn.assigns.current_user

    if current_user && current_user.moderator do
      conn
    else
      conn
      |> put_flash(
        :error,
        "You need to be logged in with a moderation account to access that page."
      )
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
