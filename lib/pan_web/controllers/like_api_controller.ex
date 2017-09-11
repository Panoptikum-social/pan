defmodule PanWeb.LikeApiController do
  use Pan.Web, :controller
  alias PanWeb.Category
  alias PanWeb.Message
  alias Pan.Like
  alias PanWeb.Podcast
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, %{"id" => id}) do
    like = Repo.get(Like, id)

    render conn, "show.json-api", data: like
  end


  def toggle(conn, %{"category_id" => category_id}, user) do
    {:ok, like} = category_id
                  |> String.to_integer()
                  |> Category.like(user.id)

    like = like
           |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
           |> mark_if_deleted()

    e = %Event{
      topic:           "categories",
      subtopic:        category_id,
      current_user_id: user.id,
      category_id:     String.to_integer(category_id),
      type:            "success",
      event:           "like"
    }
    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "category"]
  end


  def toggle(conn, %{"podcast_id" => podcast_id}, user) do
    {:ok, like} = podcast_id
                  |> String.to_integer()
                  |> Podcast.like(user.id)

    like = like
           |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
           |> mark_if_deleted()

    e = %Event{
      topic:           "podcasts",
      subtopic:        podcast_id,
      current_user_id: user.id,
      podcast_id:      String.to_integer(podcast_id),
      type:            "success",
      event:           "like"
    }
    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "podcast"]
  end
end
