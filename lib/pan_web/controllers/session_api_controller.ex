defmodule PanWeb.SessionApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.Auth
  alias PanWeb.Endpoint
  alias PanWeb.ErrorApiView

  def login(conn, %{"username" => username, "password" => given_pass}) do
    conn = fetch_session(conn)

    case Auth.login_by_username_and_pass(conn, username, given_pass) do
      {:ok, conn} ->
        current_user = conn.assigns.current_user
        token = Phoenix.Token.sign(Endpoint, "user", current_user.id)

        unless current_user.email_confirmed do
          conn
          |> put_view(ErrorApiView)
          |> put_status(401)
          |> render(:errors, data: %{code: 401,
                                     status: 401,
                                     title: "Unauthorized",
                                     detail: "email address not confirmed yet, click the confirmation link in the email"})
        end

        data = %{id: current_user.id,
                 token: token,
                 created_at: Timex.now(),
                 valid_for: "1 hour",
                 valid_until: Timex.shift(Timex.now(), hours: 1)}

        conn = Plug.Conn.put_resp_header(conn, "token", token)

        render conn, "show.json-api", data: data

      {:error, _reason, _conn} ->
        token = "Could not be aquired. Wrong username/password combination?"
    end
  end
end