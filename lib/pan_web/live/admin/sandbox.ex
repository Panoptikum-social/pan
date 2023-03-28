defmodule PanWeb.Live.Admin.Sandbox do
  use Surface.LiveView, layout: {PanWeb.LayoutView, :live_admin}

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_info(%{event: event, payload: payload, topic: "admin"}, socket) do
    {:noreply, push_event(socket, event, payload)}
  end

  def render(assigns) do
    ~F"""
    <div class="m-4"
         x-data="{isShow: false}">
      <button class="bg-gray-light rounded hover:bg-gray-lighter px-6 py-1"
              x-on:click="isShow = true; setTimeout(() => isShow = false, 5000)">Trigger</button>
      <div x-show="isShow"
           class="absolute top-0 right-4 m-3 w-2/3 md:w-1/3">
        <div class="bg-white border-gray border p-3 flex items-start shadow-md rounded-md space-x-2">
          <div class="flex-shrink-0">✅</div>
          <div class="flex-1 space-y-1">
            <p class="text-base leading-6 font-medium text-gray-700">Heading</p>
            <p class="text-sm leading-5 text-gray-600">Some Text</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
