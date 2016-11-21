defmodule Pan.UserChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.User
  alias Pan.Message

  def join("users:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end


  def handle_in("like", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    current_user_id = socket.assigns[:current_user_id]
    user_id = String.to_integer(params["user_id"])
    content = "I " <> params["action"] <> "d the user <b>" <>
              Repo.get!(User, user_id).name <> "</b>"
    type = "success"

    User.like(user_id, current_user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "like",
             content: content,
             creator_id: current_user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "like", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.UserFrontendView,
                                            "like_button.html",
                                            current_user_id: current_user_id,
                                            user_id: user_id)}
    {:reply, :ok, socket}
  end


  def handle_in("follow", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    current_user_id = socket.assigns[:current_user_id]
    user_id = String.to_integer(params["user_id"])
    content = "I " <> params["action"] <> "ed the user <b>" <>
              Repo.get!(User, user_id).name <> "</b>"
    type = "success"

    User.follow(user_id, current_user_id)

    %Message{topic: topic,
             subtopic: subtopic,
             event: "follow",
             content: content,
             creator_id: current_user_id,
             type: type}
    |> Repo.insert

    broadcast! socket, "follow", %{
      content: content,
      type: type,
      button: Phoenix.View.render_to_string(Pan.UserFrontendView,
                                            "follow_button.html",
                                            current_user_id: current_user_id,
                                            user_id: user_id)}
    {:reply, :ok, socket}
  end

end