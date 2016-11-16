defmodule Pan.CategoryChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Category

  def join("categories:" <> category_id, _params, socket) do
    {:ok, assign(socket, :category_id, String.to_integer(category_id))}
  end

  def handle_in("like", params, socket) do
    broadcast! socket, "like", %{
      enjoyer:  Repo.get!(User,     String.to_integer(params["enjoyer_id"])).name,
      category: Repo.get!(Category, String.to_integer(params["category_id"])).title
    }

    {:reply, :ok, socket}
  end
end