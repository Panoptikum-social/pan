defmodule PanWeb.UserSocket do
  use Phoenix.Socket

  channel "users:*",      PanWeb.UserChannel
  channel "personas:*",   PanWeb.PersonaChannel
  channel "mailboxes:*",  PanWeb.MailboxChannel
  channel "categories:*", PanWeb.CategoryChannel
  channel "podcasts:*",   PanWeb.PodcastChannel
  channel "episodes:*",   PanWeb.EpisodeChannel

  @max_age 4 * 7 * 24 * 60 * 60

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: @max_age) do
      {:ok, user_id} ->
        {:ok, assign(socket, :current_user_id, user_id)}
      {:error, _reason} ->
        :error
    end
  end
  def connect(_params, _socket), do: :error

  def id(socket), do: "users_socket:#{socket.assigns.current_user_id}"
end
