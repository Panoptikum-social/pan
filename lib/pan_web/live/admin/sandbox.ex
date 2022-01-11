defmodule PanWeb.Live.Admin.Sandbox do
  use Surface.LiveView, layout: {PanWeb.LayoutView, "live_admin.html"}

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Pan.PubSub, "admin", link: true)
    {:ok, socket}
  end

  def handle_info(message, socket) do
    IO.inspect "got #{message}"
    {:noreply, socket}
  end

  def handle_event("send", _params, socket)  do
    Phoenix.PubSub.broadcast(Pan.PubSub, "admin", "I am the message")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <button :on-click="send"
            class="m-4 bg-lavender rounded hover:bg-lavender-light px-6 py-1">
      Send Message
    </button>


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
