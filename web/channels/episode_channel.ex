defmodule Pan.EpisodeChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Episode
  alias Pan.Message
  alias Pan.Chapter

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


  def handle_in("like-chapter", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    IO.inspect params["chapter_id"]
    chapter_id = String.to_integer(params["chapter_id"])
    chapter_title = Repo.get!(Episode, chapter_id).title
                    |> Crutches.String.truncate(20)
    content = "I " <> params["action"] <> "d the chapter <b>" <>
              chapter_title <> "</b>"
    type = "success"

    Chapter.like(chapter_id, user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "like-chapter",
             content: content,
             creator_id: user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "like-chapter", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.EpisodeFrontendView,
                                            "like_chapter_button.html",
                                            user_id: user_id,
                                            chapter_id: chapter_id),
      chapter_id: chapter_id}
    {:reply, :ok, socket}
  end
end