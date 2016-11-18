defmodule Pan.PodcastChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Podcast
  alias Pan.Message

  def join("podcasts:" <> podcast_id, _params, socket) do
    {:ok, assign(socket, :podcast_id, String.to_integer(podcast_id))}
  end


  def handle_in("like", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id       = socket.assigns[:current_user_id]
    username      = Repo.get!(User, user_id).name
    podcast_id    = String.to_integer(params["podcast_id"])
    podcast_title = Repo.get!(Podcast, podcast_id).title
    content       = "User <b>" <> username <> "</b> " <> params["action"] <> "d the podcast <b>" <> podcast_title <> "</b>"
    type          = "success"

    Podcast.like(podcast_id, user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "like",
             content: content,
             creator_id: user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "like", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.PodcastFrontendView,
                                            "like_button.html",
                                            user_id: user_id,
                                            podcast_id: podcast_id)}
    {:reply, :ok, socket}
  end
end