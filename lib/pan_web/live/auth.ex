defmodule PanWeb.Live.Auth do
  import Phoenix.LiveView

  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {:cont, assign_new(socket, :current_user_id, user_id)}
  end

  def mount(_params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end
end
