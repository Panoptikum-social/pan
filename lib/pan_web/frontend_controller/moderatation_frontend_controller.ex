defmodule PanWeb.ModerationFrontendController do
  use PanWeb, :controller
  alias PanWeb.User

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def my_moderations(conn, _params, user) do
    user =
      Repo.get!(User, user.id)
      |> Repo.preload([:categories_i_moderate])

    render(conn, "my_moderations.html", categories: user.categories_i_moderate)
  end
end
