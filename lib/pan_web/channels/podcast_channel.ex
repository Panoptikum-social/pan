defmodule PanWeb.PodcastChannel do
  use PanWeb, :channel
  alias Pan.Repo
  alias PanWeb.Podcast
  alias PanWeb.Message

  def join("podcasts:" <> podcast_id, _params, socket) do
    {:ok, assign(socket, :podcast_id, String.to_integer(podcast_id))}
  end

  def handle_in("like", params, socket) do
    e = %Event{
      topic: String.split(socket.topic, ":") |> List.first(),
      subtopic: String.split(socket.topic, ":") |> List.last(),
      current_user_id: socket.assigns[:current_user_id],
      podcast_id: String.to_integer(params["podcast_id"]),
      type: "success",
      event: "like"
    }

    e = %{
      e
      | content:
          "« " <>
            params["action"] <>
            "d the podcast <b>" <>
            Repo.get!(Podcast, e.podcast_id).title <> "</b> »"
    }

    Podcast.like(e.podcast_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button =
      Phoenix.View.render_to_string(
        PanWeb.PodcastFrontendView,
        "like_button.html",
        user_id: e.current_user_id,
        podcast_id: e.podcast_id
      )

    {:reply, {:ok, %{button: button}}, socket}
  end

  def handle_in("follow", params, socket) do
    e = %Event{
      topic: String.split(socket.topic, ":") |> List.first(),
      subtopic: String.split(socket.topic, ":") |> List.last(),
      current_user_id: socket.assigns[:current_user_id],
      podcast_id: String.to_integer(params["podcast_id"]),
      type: "success",
      event: "follow"
    }

    e = %{
      e
      | content:
          "« " <>
            params["action"] <>
            "ed the podcast <b>" <>
            Repo.get!(Podcast, e.podcast_id).title <> "</b> »"
    }

    Podcast.follow(e.podcast_id, e.current_user_id)

    button =
      Phoenix.View.render_to_string(
        PanWeb.PodcastFrontendView,
        "follow_button.html",
        user_id: e.current_user_id,
        podcast_id: e.podcast_id
      )

    {:reply, {:ok, %{button: button}}, socket}
  end

  def handle_in("subscribe", params, socket) do
    e = %Event{
      topic: String.split(socket.topic, ":") |> List.first(),
      subtopic: String.split(socket.topic, ":") |> List.last(),
      current_user_id: socket.assigns[:current_user_id],
      podcast_id: String.to_integer(params["podcast_id"]),
      type: "success",
      event: "subscribe"
    }

    e = %{
      e
      | content:
          "« " <>
            params["action"] <>
            "d the podcast <b>" <>
            Repo.get!(Podcast, e.podcast_id).title <> "</b> »"
    }

    Podcast.subscribe(e.podcast_id, e.current_user_id)
    # Message.persist_event(e)
    # Event.notify_subscribers(e)

    button =
      Phoenix.View.render_to_string(
        PanWeb.PodcastFrontendView,
        "subscribe_button.html",
        user_id: e.current_user_id,
        podcast_id: e.podcast_id
      )

    {:reply, {:ok, %{button: button}}, socket}
  end
end
