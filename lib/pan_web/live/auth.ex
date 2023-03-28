defmodule PanWeb.Live.Auth do
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, %{"user_id" => user_id} = _session, socket) do
    {:cont, assign_new(socket, :current_user_id, fn -> user_id end)}
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end

  def on_mount(:admin, _params, %{"user_id" => user_id, "admin" => admin} = _session, socket) do
    {:cont,
     socket
     |> assign_new(:current_user_id, fn -> user_id end)
     |> assign_new(:admin, fn -> admin end)}
  end

  def on_mount(:admin, _params, _session, socket) do
    {:halt, redirect(socket, to: "/login")}
  end
end
