defmodule PanWeb.ModerationFrontendController do
  use PanWeb, :controller
  alias PanWeb.{Follow, User}

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def my_moderations(conn, _params, user) do
    user =
      Repo.get!(User, user.id)
      |> Repo.preload([:categories_i_moderate, :communities_i_moderate])

    # moderating a community gives no access to its pads without following it
    unfollowed_communities =
      Enum.reject(user.communities_i_moderate, &Follow.find_community_follow(user.id, &1.id))

    render(conn, "my_moderations.html",
      categories: user.categories_i_moderate,
      unfollowed_communities: unfollowed_communities
    )
  end
end
