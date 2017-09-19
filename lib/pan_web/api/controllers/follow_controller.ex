defmodule PanWeb.Api.FollowController do
  use Pan.Web, :controller
  alias PanWeb.Category
  alias PanWeb.Follow
  alias PanWeb.Podcast
  alias PanWeb.Persona
  alias PanWeb.User
  alias PanWeb.Subscription
  alias PanWeb.Message
  alias PanWeb.Api.Helpers
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, %{"id" => id}, _user) do
    follow = from(f in Follow, join: u in assoc(f, :follower),
                               where: (f.id == ^id and u.share_follows == true),
                               limit: 1,
                               preload: [:category, :follower, :user, :podcast, :persona])
             |> Repo.all()

    if follow != [] do
      render conn, "show.json-api", data: follow,
                                  opts: [include: "category,follower,user,podcast,persona"]
    else
      Helpers.send_404(conn)
    end
  end


  def toggle(conn, %{"persona_id" => persona_id}, user) do
    with %PanWeb.Persona{} <- Repo.get(Persona, persona_id) do
      {:ok, follow} = persona_id
                    |> String.to_integer()
                    |> Persona.follow(user.id)

      follow = follow
             |> Repo.preload([:category, :follower, :user, :podcast, :persona])
             |> mark_if_deleted()

      render conn, "show.json-api", data: follow,
                                    opts: [include: "persona"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def toggle(conn, %{"user_id" => user_id}, current_user) do
    with %PanWeb.User{} <- Repo.get(User, user_id) do
      {:ok, follow} = user_id
                      |> String.to_integer()
                      |> User.follow(current_user.id)

      follow = follow
               |> Repo.preload([:category, :follower, :user, :podcast, :persona])
               |> mark_if_deleted()

      render conn, "show.json-api", data: follow,
                                    opts: [include: "user"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    with %PanWeb.Podcast{} <- Repo.get(Podcast, podcast_id) do
      {:ok, follow} = podcast_id
                      |> String.to_integer()
                      |> Podcast.follow(user.id)

      follow = follow
               |> Repo.preload([:category, :follower, :user, :podcast, :persona])
               |> mark_if_deleted()

      render conn, "show.json-api", data: follow,
                                    opts: [include: "podcast"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def toggle(conn, %{"category_id" => category_id}, user) do
    with %PanWeb.Category{} <- Repo.get(Category, category_id) do
      {:ok, follow} = category_id
                      |> String.to_integer()
                      |> Category.follow(user.id)

      follow = follow
               |> Repo.preload([:category, :follower, :user, :podcast, :persona])
               |> mark_if_deleted()

      render conn, "show.json-api", data: follow,
                                    opts: [include: "category"]
    else
      nil -> Helpers.send_404(conn)
    end
  end


  def follow_all_subscribed_podcasts(conn, _params, user) do
    subscribed_podcast_ids = from(s in Subscription, where: s.user_id == ^user.id,
                                                     select: s.podcast_id)
                             |> Repo.all()
    followed_ids = from(f in Follow, where: f.follower_id == ^user.id and
                                     not is_nil(f.podcast_id),
                                     select: f.podcast_id)
                   |> Repo.all()

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

    follows = from(f in Follow, where: f.follower_id == ^user.id and
                                       not is_nil(f.podcast_id),
                                preload: [:category, :follower, :user, :podcast, :persona])
              |> Repo.all()


    render conn, "index.json-api", data: follows,
                                   opts: [include: "follower,podcast"]
  end
end