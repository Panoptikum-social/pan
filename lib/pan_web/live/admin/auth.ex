defmodule PanWeb.Live.Admin.Auth do
  import Phoenix.LiveView

  def mount(_params, %{"user_id" => user_id, "admin" => admin} = _session, socket) do
    socket =
      socket
      |> assign(:current_user_id, user_id)
      |> assign(:admin, admin)
    {:cont, socket}
  end

  def mount(_params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end
end
