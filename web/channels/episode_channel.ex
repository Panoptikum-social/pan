defmodule Pan.EpisodeChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Episode
  alias Pan.Message
  alias Pan.Chapter
  alias Pan.Gig

  def join("episodes:" <> episode_id, _params, socket) do
    {:ok, assign(socket, :episode_id, String.to_integer(episode_id))}
  end


  def handle_in("like", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      episode_id:      String.to_integer(params["episode_id"]),
      type:            "success",
      event:           "like"
    }
    e = %{e | content: "« " <> params["action"] <> "d the episode <b>" <>
                       Repo.get!(Episode, e.episode_id).title <> "</b> »"}

    Episode.like(e.episode_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(Pan.EpisodeFrontendView,
                                           "like_button.html",
                                           user_id: e.current_user_id,
                                           episode_id: e.episode_id)
    {:reply, {:ok, %{button: button}}, socket}
  end


  def handle_in("like-chapter", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      chapter_id:      String.to_integer(params["chapter_id"]),
      type:            "success",
      event:           "like-chapter"
    }
    chapter_title = Repo.get!(Chapter, e.chapter_id).title
                    |> Pan.ViewHelpers.truncate(40)
    e = %{e | content: "« " <> params["action"] <> "d the episode <b> »" <>
                       chapter_title <> "</b>"}

    Chapter.like(e.chapter_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(Pan.EpisodeFrontendView,
                                           "like_chapter_button.html",
                                           user_id: e.current_user_id,
                                           chapter_id: e.chapter_id)
    {:reply, {:ok, %{button: button}}, socket}
  end


  def handle_in("proclaim", params, socket) do
    current_user_id = socket.assigns[:current_user_id]
    episode_id = String.to_integer(params["episode_id"])
    persona_id = String.to_integer(params["persona_id"])

    Gig.proclaim(episode_id, persona_id, current_user_id)

    button = Phoenix.View.render_to_string(Pan.EpisodeFrontendView,
                                           "proclaim_button.html",
                                           episode_id: episode_id,
                                           persona_id: persona_id)
    {:reply, {:ok, %{button: button}}, socket}
  end
end