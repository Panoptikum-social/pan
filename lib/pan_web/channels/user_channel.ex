defmodule PanWeb.UserChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias PanWeb.User
  alias PanWeb.Message

  def join("users:" <> user_id, _params, socket) do
    {:ok, assign(socket, :user_id, String.to_integer(user_id))}
  end


  def handle_in("like", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      user_id:         String.to_integer(params["user_id"]),
      type:            "success",
      event:           "like"
    }
    e = %{e | content: "« " <> params["action"] <> "d the user <b>" <>
                       Repo.get!(User, e.user_id).name <> "</b> »"}

    User.like(e.user_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(PanWeb.UserFrontendView,
                                           "like_button.html",
                                           current_user_id: e.current_user_id,
                                           user_id: e.user_id)
    {:reply, {:ok, %{button: button}}, socket}
  end


  def handle_in("follow", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      user_id:         String.to_integer(params["user_id"]),
      type:            "success",
      event:           "follow"
    }
    e = %{e | content: "« " <> params["action"] <> "ed the user <b>" <>
                       Repo.get!(User, e.user_id).name <> "</b> »"}

    User.follow(e.user_id, e.current_user_id)
    # Message.persist_event(e)
    # Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(PanWeb.UserFrontendView,
                                           "follow_button.html",
                                           current_user_id: e.current_user_id,
                                           user_id: e.user_id)
    {:reply, {:ok, %{button: button}}, socket}
  end
end