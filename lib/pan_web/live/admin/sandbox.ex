defmodule PanWeb.Live.Admin.Sandbox do
  use PanWeb, :admin_live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_info(%{event: event, payload: payload, topic: "admin"}, socket) do
    {:noreply, push_event(socket, event, payload)}
  end

  def render(assigns) do
    ~H"""
    <div
      class="m-4"
      x-data="toast"
    >
      <button
        class="btn"
        x-on:click="show"
      >Trigger</button>
      <div
        x-show="isShow"
        class="absolute top-0 right-4 m-3 w-2/3 md:w-1/3"
      >
        <div class="bg-base-100 border-base-300 border p-3 flex items-start shadow-md rounded-md space-x-2">
          <div class="shrink-0">✅</div>
          <div class="flex-1 space-y-1">
            <p class="text-base leading-6 font-medium text-base-content">Heading</p>
            <p class="text-sm leading-5 text-base-content/70">Some Text</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
