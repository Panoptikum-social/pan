defmodule PanWeb.Api.SessionController do
  use PanWeb, :controller
  use JaSerializer
  alias PanWeb.{Auth, Endpoint}
  import PanWeb.Api.Helpers, only: [send_401: 2]
  import Pan.Parser.MyDateTime, only: [now: 0, time_shift: 2]

  def login(conn, %{"username" => username, "password" => given_pass}) do
    conn = fetch_session(conn)

    case Auth.login_by_username_and_pass(conn, username, given_pass) do
      {:ok, conn} ->
        current_user = conn.assigns.current_user
        token = Phoenix.Token.sign(Endpoint, "user", current_user.id)

        unless current_user.email_confirmed do
          send_401(
            conn,
            "email address not confirmed yet, click the confirmation link in the email"
          )
        end

        data = %{
          id: current_user.id,
          token: token,
          inserted_at: now(),
          valid_for: "1 hour",
          valid_until: time_shift(now(), hours: 1)
        }

        conn = Plug.Conn.put_resp_header(conn, "token", token)

        render(conn, "show.json-api", data: data)

      {:error, _reason, _conn} ->
        send_401(conn, "Could not be aquired. Wrong username/password combination?")
    end
  end
end
