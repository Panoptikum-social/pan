defmodule Pan.UserFrontendController do
  use Pan.Web, :controller
  alias Pan.Message
  alias Pan.User
  alias Pan.Like
  alias Pan.Follow
  alias Pan.Subscription
  alias Pan.Podcast


  plug :scrub_params, "user" when action in [:create, :update]


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def index(conn, _params, _user) do
    users = Repo.all(from u in Pan.User, order_by: :name)
    render conn, "index.html", users: users
  end


  def new(conn, _params, _user) do
    changeset = User.changeset(%User{})
    render conn, "new.html", changeset: changeset
  end


  def create(conn, %{"user" => user_params}, _user) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        Phoenix.Token.sign(Pan.Endpoint, "user", user.id)
        |> Pan.Email.email_confirmation_link_html_email(user.email)
        |> Pan.Mailer.deliver_now()

        conn
        |> Pan.Auth.login(user)
        |> put_flash(:info, "Your account @#{user.name} has been created!")
        |> redirect(to: category_frontend_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end


  def show(conn, params, _user) do
    id = String.to_integer(params["id"])
    user = Repo.one(from u in Pan.User, where: u.id == ^id)
           |> Repo.preload([:users_i_like,
                            :categories_i_like,
                            :podcasts_i_subscribed])

    podcast_related_likes = Repo.all(from l in Like, where: l.enjoyer_id == ^id
                                                            and not is_nil(l.podcast_id),
                                                     order_by: [desc: :inserted_at])
                            |> Repo.preload([:podcast, [episode: :podcast], [chapter: [episode: :podcast]]])

    messages = from(m in Message, where: m.creator_id == ^id,
                                  order_by: [desc: :inserted_at],
                                  preload: [:creator])
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
    changeset = User.self_change_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
         conn
         |> put_flash(:info, "Account updated successfully.")
         |> redirect(to: user_frontend_path(conn, :my_profile))
      {:error, changeset} ->

         render(conn, "edit.html", user: user, changeset: changeset)
    end
  end


  def edit_password(conn, _params, user) do
    changeset = User.changeset(user)
    render(conn, "edit_password.html", user: user, changeset: changeset)
  end


  def update_password(conn, %{"user" => user_params}, user) do
    changeset = User.password_update_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, _user} ->
         conn
         |> put_flash(:info, "Password updated successfully.")
         |> redirect(to: user_frontend_path(conn, :my_profile))
      {:error, changeset} ->

         render(conn, "edit_password.html", user: user, changeset: changeset)
    end
  end


  def my_profile(conn, _params, user) do
    user = from(u in User, where: u.id == ^user.id,
                           preload: [:personas])
           |> Repo.one()

    render conn, "my_profile.html", user: user
  end


  def my_messages(conn, params, user) do
    user_id = Integer.to_string(user.id)

    subscribed_user_ids = User.subscribed_user_ids(user_id)
    subscribed_category_ids = User.subscribed_category_ids(user_id)
    subscribed_podcast_ids = User.subscribed_podcast_ids(user_id)

    messages = from(m in Message,
               where: (m.topic == "mailboxes" and m.subtopic == ^user_id) or
                      (m.topic == "users"     and m.subtopic in ^subscribed_user_ids) or
                      (m.topic == "podcasts"  and m.subtopic in ^subscribed_podcast_ids) or
                      (m.topic == "category"  and m.subtopic in ^subscribed_category_ids),
               order_by: [desc: :inserted_at],
               preload: [:creator])
               |> Repo.paginate(params)

    render conn, "my_messages.html", user: user,
                                     messages: messages,
                                     page_number: messages.page_number
  end


  def my_podcasts(conn, _params, user) do
    user = Repo.get(User, user.id)
           |> Repo.preload(podcasts_i_subscribed: from(p in Podcast, order_by: p.title))
           |> Repo.preload(podcasts_i_follow: from(p in Podcast, order_by: p.title))

    podcast_ids = from(l in Like, where: l.enjoyer_id == ^user.id and
                                         is_nil(l.chapter_id) and
                                         is_nil(l.episode_id) and
                                         not is_nil(l.podcast_id),
                                  select: l.podcast_id)
                  |> Repo.all()

    podcasts_i_like = from(p in Podcast, where: p.id in ^podcast_ids,
                                         order_by: :title)
                      |> Repo.all()

    podcasts_subscribed_ids = from(s in Subscription, where: s.user_id == ^user.id,
                                                      select: s.podcast_id)
                              |> Repo.all()

    other_subscriber_ids = from(s in Subscription, where: s.podcast_id in ^podcasts_subscribed_ids,
                                                   select: s.user_id)
                           |> Repo.all()
                           |> Enum.uniq
                           |> List.delete(user.id)

    recommendations = from(s in Subscription, join: p in assoc(s, :podcast),
                                              where: s.user_id in ^other_subscriber_ids and
                                                     not s.podcast_id in ^podcasts_subscribed_ids,
                                              group_by: p.id,
                                              select: [count(s.podcast_id), p.id, p.title],
                                              order_by: [desc: count(s.podcast_id)],
                                              limit: 10)
                      |> Repo.all()

    users_also_liking = from(l in Like, where: l.podcast_id in ^podcast_ids and
                                               is_nil(l.chapter_id) and
                                               is_nil(l.episode_id),
                                        select: l.enjoyer_id)
                        |> Repo.all()
                        |> Enum.uniq
                        |> List.delete(user.id)

    also_liked = from(l in Like, join: p in assoc(l, :podcast),
                                 where: l.enjoyer_id in ^users_also_liking and
                                        is_nil(l.chapter_id) and
                                        is_nil(l.episode_id) and
                                        not l.podcast_id in ^podcast_ids,
                                 group_by: p.id,
                                 select: [count(l.podcast_id), p.id, p.title],
                                 order_by: [desc: count(l.podcast_id)],
                                 limit: 10)
                 |> Repo.all()

    render(conn, "my_podcasts.html", user: user,
                                     podcasts_i_like: podcasts_i_like,
                                     recommendations: recommendations,
                                     also_liked: also_liked)
  end


  def like_all_subscribed(conn, _params, user) do
    subscribed_podcast_ids = Repo.all(from s in Subscription,
                                      where: s.user_id == ^user.id,
                                      select: s.podcast_id)
    liked_ids = Repo.all(from l in Like,
                         where: l.enjoyer_id == ^user.id and
                                not is_nil(l.podcast_id) and
                                is_nil(l.chapter_id) and
                                is_nil(l.episode_id),
                         select: l.podcast_id)

    for id <- subscribed_podcast_ids do
      unless Enum.member?(liked_ids, id) do
        e = %Event{
          topic:           "podcast",
          subtopic:        Integer.to_string(id),
          current_user_id: user.id,
          podcast_id:      id,
          type:            "success",
          event:           "like"
        }
        e = %{e | content: "« liked the podcast <b>" <>
                           Repo.get!(Podcast, e.podcast_id).title <> "</b> »"}

        Podcast.like(e.podcast_id, e.current_user_id)
        Message.persist_event(e)
        Event.notify_subscribers(e)
      end
    end

    conn
    |> put_flash(:info, "Liked all podcasts you had subscribed to.")
    |> redirect(to: user_frontend_path(conn, :my_podcasts))
  end


  def follow_all_subscribed(conn, _params, user) do
    subscribed_podcast_ids = Repo.all(from s in Subscription,
                                      where: s.user_id == ^user.id,
                                      select: s.podcast_id)
    followed_ids = Repo.all(from f in Follow,
                         where: f.follower_id == ^user.id and
                                not is_nil(f.podcast_id),
                         select: f.podcast_id)

    for id <- subscribed_podcast_ids do
      unless Enum.member?(followed_ids, id) do
        e = %Event{
          topic:           "podcast",
          subtopic:        Integer.to_string(id),
          current_user_id: user.id,
          podcast_id:      id,
          type:            "success",
          event:           "follow"
        }
        e = %{e | content: "« followed the podcast <b>" <>
                           Repo.get!(Podcast, e.podcast_id).title <> "</b> »"}

        Podcast.follow(e.podcast_id, e.current_user_id)
        Message.persist_event(e)
        Event.notify_subscribers(e)
      end
    end

    conn
    |> put_flash(:info, "Followed all podcasts you had subscribed to.")
    |> redirect(to: user_frontend_path(conn, :my_podcasts))
  end
end