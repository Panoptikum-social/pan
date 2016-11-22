defmodule Pan.UserFrontendController do
  use Pan.Web, :controller
  alias Pan.Message
  alias Pan.Follow

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def profile(conn, params, user) do
    user_id = Integer.to_string(user.id)

    subscribed_user_ids =
      case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                             not is_nil(f.user_id),
                                      select: f.user_id) do
        [] -> ["0"]
        array -> Enum.map(array, fn(id) ->  Integer.to_string(id) end)
      end

    subscribed_category_ids =
      case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                             not is_nil(f.category_id),
                                      select: f.category_id) do
        [] -> ["0"]
        array -> Enum.map(array, fn(id) ->  Integer.to_string(id) end)
    end

    subscribed_podcast_ids =
      case Repo.all(from f in Follow, where: f.follower_id == ^user_id and
                                             not is_nil(f.podcast_id),
                                      select: f.podcast_id) do
        [] -> ["0"]
        array -> Enum.map(array, fn(id) ->  Integer.to_string(id) end)
      end


    query = from m in Message,
            where: (m.topic == "mailboxes" and m.subtopic == ^user_id) or
                   (m.topic == "users" and m.subtopic in ^subscribed_user_ids) or
                   (m.topic == "podcasts" and m.subtopic in ^subscribed_podcast_ids) or
                   (m.topic == "category" and m.subtopic in ^subscribed_category_ids),
            order_by: [desc: :inserted_at],
            preload: [:creator]

    messages = query
               |> Ecto.Queryable.to_query
               |> Repo.paginate(params)

    render conn, "profile.html", user: user, messages: messages,
                                             page_number: messages.page_number,
                                             page_size: messages.page_size,
                                             total_pages: messages.total_pages,
                                             total_entries: messages.total_entries
  end


  def index(conn, _params, _user) do
    users = Repo.all(from u in Pan.User, order_by: :name,
                                         where: u.podcaster == true)
    render conn, "index.html", users: users
  end


  def show(conn, %{"id" => id}, _user) do
    user = Repo.one(from u in Pan.User, where: u.id == ^id and u.podcaster == true)
           |> Repo.preload(:owned_podcasts)
    render conn, "show.html", user: user
  end
end