defmodule PanWeb.PersonaChannel do
  use Pan.Web, :channel
  alias Pan.Repo
  alias PanWeb.Persona
  alias PanWeb.Message

  def join("personas:" <> persona_id, _params, socket) do
    {:ok, assign(socket, :persona_id, String.to_integer(persona_id))}
  end


  def handle_in("like", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      persona_id:      String.to_integer(params["persona_id"]),
      type:            "success",
      event:           "like"
    }
    e = %{e | content: "« " <> params["action"] <> "d the persona <b>" <>
                       Repo.get!(Persona, e.persona_id).name <> "</b> »"}

    Persona.like(e.persona_id, e.current_user_id)
    Message.persist_event(e)
    Event.notify_subscribers(e)

    button = Phoenix.View.render_to_string(PanWeb.PersonaFrontendView,
                                           "like_button.html",
                                           current_user_id: e.current_user_id,
                                           persona_id: e.persona_id)
    {:reply, {:ok, %{button: button}}, socket}
  end


  def handle_in("follow", params, socket) do
    e = %Event{
      topic:           String.split(socket.topic, ":") |> List.first,
      subtopic:        String.split(socket.topic, ":") |> List.last,
      current_user_id: socket.assigns[:current_user_id],
      persona_id:      String.to_integer(params["persona_id"]),
      type:            "success",
      event:           "follow"
    }
    e = %{e | content: "« " <> params["action"] <> "ed the persona <b>" <>
                       Repo.get!(Persona, e.persona_id).name <> "</b> »"}

    Persona.follow(e.persona_id, e.current_user_id)

    button = Phoenix.View.render_to_string(PanWeb.PersonaFrontendView,
                                           "follow_button.html",
                                           current_user_id: e.current_user_id,
                                           persona_id: e.persona_id)
    {:reply, {:ok, %{button: button}}, socket}
  end
end