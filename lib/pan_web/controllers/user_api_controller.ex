defmodule PanWeb.UserApiController do
  use Pan.Web, :controller
  use JaSerializer
  alias PanWeb.User


  def show(conn, %{"id" => id} = params) do
    user = Repo.get(User, id)
           |> Repo.preload([:categories_i_like, :users_i_like])

    include_string = "categories_i_like,users_i_like"

    {user, include_string} =
      if user.share_subscriptions do
        {Repo.preload(user, :podcasts_i_subscribed), include_string <> ",podcasts_i_subscribed"}
      else
        {user, include_string}
      end

    {user, include_string} =
      if user.share_follows do
        {Repo.preload(user, :podcasts_i_follow), include_string <> ",podcasts_i_follow"}
      else
        {user, include_string}
      end

    render conn, "show.json-api", data: user,
                                  opts: [include: include_string]
  end
end
