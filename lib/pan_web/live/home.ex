defmodule PanWeb.Live.Home do
  use Surface.LiveView
  alias PanWeb.Surface.Panel

  def mount(_params, _session, socket) do
    socket = assign(socket, options: %{})
    {:ok, socket}
  end

#  def handle_params(params, _url, socket) do
#    {:noreply, socket}
#  end
end
