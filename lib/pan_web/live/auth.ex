defmodule PanWeb.Live.Auth do
  import Phoenix.LiveView

  def on_mount(:default, _params, %{"user_id" => user_id} = _session, socket) do
    {:cont, assign(socket, :current_user_id, user_id)}
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end
end
