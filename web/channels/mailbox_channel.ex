defmodule Pan.MailboxChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Podcast


  def join("mailboxes:" <> user_id, _params, socket) do
    if String.to_integer(user_id) == socket.assigns[:current_user_id] do
      {:ok, socket}
    else
      {:error, "That's not your channel"}
    end
  end

  def handle_in("like", params, socket) do
    broadcast! socket, "like", %{
      enjoyer: Repo.get!(User, socket.assigns[:current_user_id]).name,
      podcast: Repo.get!(Podcast, String.to_integer(params["podcast_id"])).title,
      action: params["action"]
    }

    {:reply, :ok, socket}
  end
end