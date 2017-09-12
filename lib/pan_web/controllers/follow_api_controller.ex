defmodule PanWeb.FollowApiController do
  use Pan.Web, :controller
  alias PanWeb.Category
  alias Pan.Follow
  alias PanWeb.Podcast
  alias PanWeb.Persona
  alias PanWeb.User
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, %{"id" => id}) do
    follow = Repo.get(Follow, id)

    render conn, "show.json-api", data: follow
  end


  def toggle(conn, %{"persona_id" => persona_id}, user) do
    {:ok, follow} = persona_id
                  |> String.to_integer()
                  |> Persona.follow(user.id)

    follow = follow
           |> Repo.preload([:category, :follower, :user, :podcast, :persona])
           |> mark_if_deleted()

    render conn, "show.json-api", data: follow,
                                  opts: [include: "persona"]
  end


  def toggle(conn, %{"user_id" => user_id}, current_user) do
    {:ok, follow} = user_id
                    |> String.to_integer()
                    |> User.follow(current_user.id)

    follow = follow
             |> Repo.preload([:category, :follower, :user, :podcast, :persona])
             |> mark_if_deleted()

    render conn, "show.json-api", data: follow,
                                  opts: [include: "user"]
  end


  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    {:ok, follow} = podcast_id
                    |> String.to_integer()
                    |> Podcast.follow(user.id)

    follow = follow
             |> Repo.preload([:category, :follower, :user, :podcast, :persona])
             |> mark_if_deleted()

    render conn, "show.json-api", data: follow,
                                  opts: [include: "podcast"]
  end


  def toggle(conn, %{"category_id" => category_id}, user) do
    {:ok, follow} = category_id
                    |> String.to_integer()
                    |> Category.follow(user.id)

    follow = follow
             |> Repo.preload([:category, :follower, :user, :podcast, :persona])
             |> mark_if_deleted()

    render conn, "show.json-api", data: follow,
                                  opts: [include: "category"]
  end
end