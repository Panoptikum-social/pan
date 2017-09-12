defmodule PanWeb.ApiAuth do
  import Plug.Conn
  import Phoenix.Controller, only: [render: 3, put_view: 2]

  alias Pan.Repo
  alias PanWeb.User
  alias PanWeb.ErrorApiView


  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end


  def call(conn, _repo) do
    token = conn
            |> get_req_header("authorization")
            |> List.first()

    token = token && String.slice(token, 7..-1)

    case Phoenix.Token.verify(PanWeb.Endpoint, "user", token, max_age: 60 * 60) do
      {:ok, user_id} ->
        user = Repo.get!(User, user_id)
        if user.email_confirmed do
          assign(conn, :current_user, user)
        else
          conn
          |> assign(:current_user, nil)
          |> assign(:api_error, "email address not confirmed yet, click the confirmation link in the email")
        end
      {:error, error} ->
        conn
        |> assign(:current_user, nil)
        |> assign(:api_error, "token " <> Atom.to_string(error))
      true ->
        conn
        |> assign(:current_user, nil)
        |> assign(:api_error, "token error")
    end
  end


  def send_error(conn, reason) do
    conn
    |> put_view(ErrorApiView)
    |> put_status(401)
    |> render(:errors, data: %{code: 401,
                               status: 401,
                               title: "Unauthorized",
                               detail: reason})
  end


  def authenticate_api_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> send_error(conn.assigns.api_error)
      |> halt()
    end
  end
end
