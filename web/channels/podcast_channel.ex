defmodule Pan.PodcastChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Podcast
  alias Pan.Message
  alias Pan.User

  def join("podcasts:" <> podcast_id, _params, socket) do
    {:ok, assign(socket, :podcast_id, String.to_integer(podcast_id))}
  end


  def handle_in("like", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    user_name = Repo.get(User, user_id).name
    podcast_id = String.to_integer(params["podcast_id"])
    content = "I " <> params["action"] <> "d the podcast <b>" <>
              Repo.get!(Podcast, podcast_id).title <> "</b>"
    type = "success"

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
                                            podcast_id: podcast_id),
      user_id: user_id,
      user_name: user_name}
    {:reply, :ok, socket}
  end


  def handle_in("follow", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    user_name = Repo.get(User, user_id).name
    podcast_id = String.to_integer(params["podcast_id"])
    content = "I " <> params["action"] <> "ed the podcast <b>" <>
              Repo.get!(Podcast, podcast_id).title <> "</b>"
    type = "success"

    Podcast.follow(podcast_id, user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "follow",
             content: content,
             creator_id: user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "follow", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.PodcastFrontendView,
                                            "follow_button.html",
                                            user_id: user_id,
                                            podcast_id: podcast_id),
      user_id: user_id,
      user_name: user_name}
    {:reply, :ok, socket}
  end


  def handle_in("subscribe", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    user_name = Repo.get(User, user_id).name
    podcast_id = String.to_integer(params["podcast_id"])
    content = "I " <> params["action"] <> "d the podcast <b>" <>
              Repo.get!(Podcast, podcast_id).title <> "</b>"
    type = "success"

    Podcast.subscribe(podcast_id, user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "subscribe",
             content: content,
             creator_id: user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "subscribe", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.PodcastFrontendView,
                                            "subscribe_button.html",
                                            user_id: user_id,
                                            podcast_id: podcast_id),
      user_id: user_id,
      user_name: user_name}
    {:reply, :ok, socket}
  end
end