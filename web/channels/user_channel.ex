defmodule Pan.UserChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Podcast

  def join("users:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end

  def handle_in("like", params, socket) do
    broadcast! socket, "like", %{
      enjoyer: Repo.get!(User, String.to_integer(socket.assigns[:current_user_id])).name,
      user:    Repo.get!(User, String.to_integer(params["user_id"])).name
    }

    {:reply, :ok, socket}
  end
end