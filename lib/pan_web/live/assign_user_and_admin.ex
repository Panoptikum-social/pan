defmodule PanWeb.Live.AssignUserAndAdmin do
  import Phoenix.LiveView

  def mount(_params, session, socket) do
    {:cont, assign(socket, current_user_id: session["user_id"], admin: session["admin"])}
  end
end
