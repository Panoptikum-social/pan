defmodule Pan.UserChannel do
  use Pan.Web, :channel

  def join("users:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end

  def handle_in("new_like", params, socket) do
    broadcast! socket, "new_like", %{
      user: Pan.Repo.get!(Pan.User, String.to_integer(params["user_id"])).name,
      podcast: Pan.Repo.get!(Pan.Podcast, String.to_integer(params["podcast_id"])).title
    }

    {:reply, :ok, socket}
  end
end