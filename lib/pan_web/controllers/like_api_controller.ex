defmodule PanWeb.LikeApiController do
  use Pan.Web, :controller
  alias PanWeb.Category
  alias PanWeb.Message
  alias Pan.Like
  alias PanWeb.Podcast
  alias PanWeb.Chapter
  alias PanWeb.Episode
  alias PanWeb.Persona
  import Pan.Parser.Helpers, only: [mark_if_deleted: 1]

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end


  def show(conn, %{"id" => id}) do
    like = Repo.get(Like, id)

    render conn, "show.json-api", data: like
  end


  def toggle(conn, %{"persona_id" => persona_id}, user) do
    {:ok, like} = persona_id
                  |> String.to_integer()
                  |> Persona.like(user.id)

    like = like
           |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
           |> mark_if_deleted()

    e = %Event{
      topic:           "personas",
      subtopic:        persona_id,
      current_user_id: user.id,
      persona_id:      String.to_integer(persona_id),
      type:            "success",
      event:           "like"
    }

    e = %{e | content: "« liked the persona <b>" <>
                       Repo.get!(Persona, e.persona_id).name <> "</b> »"}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "persona"]
  end


  def toggle(conn, %{"chapter_id" => chapter_id}, user) do
    {:ok, like} = chapter_id
                  |> String.to_integer()
                  |> Chapter.like(user.id)

    like = like
           |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
           |> mark_if_deleted()

    e = %Event{
      topic:           "chapters",
      subtopic:        chapter_id,
      current_user_id: user.id,
      chapter_id:      String.to_integer(chapter_id),
      type:            "success",
      event:           "like-chapter"
    }

    chapter_title = Repo.get!(Chapter, e.chapter_id).title
                    |> PanWeb.ViewHelpers.truncate(40)
    e = %{e | content: "« liked the chapter <b> »" <> chapter_title <> "</b>"}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "chapter"]
  end


  def toggle(conn, %{"episode_id" => episode_id}, user) do
    {:ok, like} = episode_id
                  |> String.to_integer()
                  |> Episode.like(user.id)

    like = like
           |> Repo.preload([:category, :enjoyer, :user, :podcast, :chapter, :persona, :episode])
           |> mark_if_deleted()

    e = %Event{
      topic:           "episodes",
      subtopic:        episode_id,
      current_user_id: user.id,
      episode_id:      String.to_integer(episode_id),
      type:            "success",
      event:           "like"
    }

    e = %{e | content: "« liked the episode <b>" <>
                       Repo.get!(Episode, e.episode_id).title <> "</b> »"}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "episode"]
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
    e = %{e | content: "« liked the podcast <b>" <>
                       Repo.get!(Podcast, e.podcast_id).title <> "</b> »"}

    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "podcast"]
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
    e = %{e | content: "« liked the category <b>" <>
                       Repo.get!(Category, e.category_id).title <> "</b> »"}
    Message.persist_event(e)
    Event.notify_subscribers(e)

    render conn, "show.json-api", data: like,
                                  opts: [include: "category"]
  end
end