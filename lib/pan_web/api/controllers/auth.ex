defmodule PanWeb.Api.Auth do
  import Plug.Conn
  import PanWeb.Api.Helpers, only: [send_401: 2]
  alias Pan.Repo
  alias PanWeb.User
  import Pan.Parser.MyDateTime, only: [in_the_future?: 1]

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, _repo) do
    token =
      get_req_header(conn, "authorization")
      |> List.first()

    token = token && String.slice(token, 7..-1)

    case Phoenix.Token.verify(PanWeb.Endpoint, "user", token, max_age: 60 * 60) do
      {:ok, user_id} ->
        user = Repo.get!(User, user_id)

        if user.email_confirmed do
          assign(conn, :current_user, user)
        else
          assign(conn, :current_user, nil)
          |> assign(
            :api_error,
            "email address not confirmed yet, click the confirmation link in the email"
          )
        end

      {:error, error} ->
        assign(conn, :current_user, nil)
        |> assign(:api_error, "token " <> Atom.to_string(error))
    end
  end

  def authenticate_api_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      send_401(conn, conn.assigns.api_error)
    end
  end

  def authenticate_api_pro_user(conn, _opts) do
    current_user = conn.assigns.current_user

    if current_user && in_the_future?(current_user.pro_until) do
      conn
    else
      send_401(conn, conn.assigns.api_error || "Pro account needed")
    end
  end

  def authenticate_api_moderator(conn, _opts) do
    current_user = conn.assigns.current_user

    if current_user && current_user.moderator do
      conn
    else
      send_401(conn, conn.assigns.api_error || "Moderator account needed")
    end
  end
end
