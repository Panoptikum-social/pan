defmodule Pan.EpisodeChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Episode
  alias Pan.Message

  def join("episodes:" <> episode_id, _params, socket) do
    {:ok, assign(socket, :episode_id, String.to_integer(episode_id))}
  end


  def handle_in("like", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    episode_id = String.to_integer(params["episode_id"])
    content = "I " <> params["action"] <> "d the episode <b>" <>
              Repo.get!(Episode, episode_id).title <> "</b>"
    type = "success"

    Episode.like(episode_id, user_id)

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
      button: Phoenix.View.render_to_string(Pan.EpisodeFrontendView,
                                            "like_button.html",
                                            user_id: user_id,
                                            episode_id: episode_id)}
    {:reply, :ok, socket}
  end
end