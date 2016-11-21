defmodule Pan.CategoryChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Category
  alias Pan.Message
  alias Pan.User

  def join("categories:" <> category_id, _params, socket) do
    {:ok, assign(socket, :category_id, String.to_integer(category_id))}
  end


  def handle_in("like", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    user_name = Repo.get(User, user_id).name
    category_id = String.to_integer(params["category_id"])
    content = "I " <> params["action"] <> "d the category <b>" <>
              Repo.get!(Category, category_id).title <> "</b>"
    type = "success"

    Category.like(category_id, user_id)

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
      button: Phoenix.View.render_to_string(Pan.CategoryFrontendView,
                                            "like_button.html",
                                            user_id: user_id,
                                            category_id: category_id),
      user_name: user_name}
    {:reply, :ok, socket}
  end


  def handle_in("follow", params, socket) do
    [topic, subtopic] = String.split(socket.topic, ":")
    user_id = socket.assigns[:current_user_id]
    user_name = Repo.get(User, user_id).name
    category_id = String.to_integer(params["category_id"])
    content = "I " <> params["action"] <> "ed the category <b>" <>
              Repo.get!(Category, category_id).title <> "</b>"
    type = "success"

    Category.follow(category_id, user_id)

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
      button: Phoenix.View.render_to_string(Pan.CategoryFrontendView,
                                            "follow_button.html",
                                            user_id: user_id,
                                            category_id: category_id),
      user_name: user_name}
    {:reply, :ok, socket}
  end
end