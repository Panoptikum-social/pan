defmodule PanWeb.UserJsonDownloadController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.User

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def download(conn, _params, user) do
    user = Repo.get(User, user.id)
           |> Repo.preload([:user_personas, :personas, :invoices, :podcasts_i_subscribed, :opmls,
                            :users_i_like, :podcasts_i_follow, :categories_i_like,
                            :categories_i_follow, :podcasts_i_like, :users_i_follow,
                            :messages_created, :episodes_i_like, :personas_i_follow,
                            :personas_i_like,
                            [chapters_i_like: :episode],
                            [recommendations: [:podcast, :episode, :chapter]]])


    conn
    |> render("show.json-api", data: user)
  end
end