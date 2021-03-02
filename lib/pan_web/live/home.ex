defmodule PanWeb.Live.Home do
  use Surface.LiveView
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Surface.Panel

  def mount(_params, _session, socket) do
    socket = assign(socket, options: %{})
    {:ok, socket}
  end
end
