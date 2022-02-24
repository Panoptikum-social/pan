defmodule PanWeb.Live.AssignUserAndAdmin do
  import Phoenix.LiveView

  def on_mount(:default, _params, session, socket) do
    {:cont,
     socket
     |> assign_new(:current_user_id, fn -> session["user_id"] end)
     |> assign_new(:admin, fn -> session["admin"] end)}
  end
end
