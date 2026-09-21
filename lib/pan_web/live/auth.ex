defmodule PanWeb.Live.Auth do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, %{"user_id" => user_id} = _session, socket) do
    {:cont, assign_new(socket, :current_user_id, fn -> user_id end)}
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end

  # The session's own "admin" flag is not trusted: it was set at login and can be
  # stale (an admin whose rights were revoked keeps it until the session ends).
  # The router's authenticate_admin plug checks the database on every request,
  # this does the same for the websocket mount.
  def on_mount(:admin, _params, %{"user_id" => user_id}, socket) do
    case Pan.Repo.get(PanWeb.User, user_id) do
      %{admin: true} ->
        {:cont,
         socket
         |> assign_new(:current_user_id, fn -> user_id end)
         |> assign_new(:admin, fn -> true end)}

      _ ->
        {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:admin, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end
end
