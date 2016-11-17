defmodule Pan.MailboxChannel do
  use Pan.Web, :channel
  alias Pan.Message
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
    [topic, subtopic] = String.split(socket.topic, ":")
    username =      Repo.get!(User,    socket.assigns[:current_user_id]).name
    podcast_title = Repo.get!(Podcast, String.to_integer(params["podcast_id"])).title
    content = "User <b>" <> username <> "</b> " <> params["action"] <> "d the podcast <b>" <> podcast_title <> "</b>"
    type = "warning"

    %Message{topic: topic,
             subtopic: subtopic,
             event: "like",
             content: content,
             creator_id: socket.assigns[:current_user_id],
             type: type}
    |> Repo.insert

    broadcast! socket, "like", %{content: content, type: type}
    {:reply, :ok, socket}
  end
end