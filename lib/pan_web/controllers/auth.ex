defmodule PanWeb.Auth do
  import Plug.Conn
#  import Bcrypt, only: [verify_pass: 2, no_user_verify: 0]

#  alias Pan.Repo
#  alias PanWeb.User


  def unset_cookie(conn, _opts) do
    # if not logged in yet or do not fill out a form, we can delete the cookie
    if conn.assigns[:current_user] ||
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
