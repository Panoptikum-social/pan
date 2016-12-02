defmodule Pan.CategoryChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Category
  alias Pan.Message

  def join("categories:" <> category_id, _params, socket) do
    {:ok, assign(socket, :category_id, String.to_integer(category_id))}
  end


  def handle_in("like", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      category_id:     String.to_integer(params["category_id"]),
      type:            "success",
      event:           "like"
    }
    e = %{e | content: "« " <> params["action"] <> "d the category <b>" <>
                       Repo.get!(Category, e.category_id).title <> "</b> »"}

    Category.like(e.category_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(Pan.CategoryFrontendView,
                                           "like_button.html",
                                           user_id: e.current_user_id,
                                           category_id: e.category_id)
    {:reply, {:ok, %{button: button}}, socket}
  end


  def handle_in("follow", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      category_id:     String.to_integer(params["category_id"]),
      type:            "success",
      event:           "follow"
    }
    e = %{e | content: "« " <> params["action"] <> "ed the category <b>" <>
                       Repo.get!(Category, e.category_id).title <> "</b> »"}

    Category.follow(e.category_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(Pan.CategoryFrontendView,
                                           "follow_button.html",
                                           user_id: e.current_user_id,
                                           category_id: e.category_id)
    {:reply, {:ok, %{button: button}}, socket}
  end
end