defmodule Pan.UserFrontendController do
  use Pan.Web, :controller
  alias Pan.Message
  alias Pan.User
  alias Pan.Like

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def profile(conn, params, user) do
    user_id = Integer.to_string(user.id)

    subscribed_user_ids = User.subscribed_user_ids(user_id)
    subscribed_category_ids = User.subscribed_category_ids(user_id)
    subscribed_podcast_ids = User.subscribed_podcast_ids(user_id)

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

    render conn, "profile.html", user: user,
                                 messages: messages,
                                 page_number: messages.page_number
  end


  def index(conn, _params, _user) do
    users = Repo.all(from u in Pan.User, order_by: :name,
                                         where: u.podcaster == true)
    render conn, "index.html", users: users
  end


  def show(conn, params, _user) do
    id = String.to_integer(params["id"])
    user = Repo.one(from u in Pan.User, where: u.id == ^id and u.podcaster == true)
           |> Repo.preload([:podcasts_i_own,
                            :users_i_like,
                            :categories_i_like,
                            :podcasts_i_subscribed])

    podcast_related_likes = Repo.all(from l in Like, where: l.enjoyer_id == ^id
                                                            and not is_nil(l.podcast_id),
                                                     order_by: [desc: :inserted_at])
                            |> Repo.preload([:podcast, [episode: :podcast], [chapter: [episode: :podcast]]])

    query = from m in Message,
            where: m.creator_id == ^id,
            order_by: [desc: :inserted_at],
            preload: [:creator]

    messages = query
               |> Ecto.Queryable.to_query
               |> Repo.paginate(params)

    render conn, "show.html", user: user,
                              podcast_related_likes: podcast_related_likes,
                              messages: messages
   end


   def edit(conn, _params, user) do
    changeset = User.changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end


  def update(conn, %{"user" => user_params}, user) do
    changeset = User.password_update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
         conn
         |> put_flash(:info, "Password updated successfully.")
         |> redirect(to: user_path(conn, :show, user))
      {:error, changeset} ->

         render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end