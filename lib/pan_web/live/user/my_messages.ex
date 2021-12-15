defmodule PanWeb.Live.User.MyMessages do
  use Surface.LiveView
  on_mount PanWeb.Live.Auth
  alias PanWeb.Message
  alias PanWeb.Surface.Pill
  require Integer

  def mount(_params, _session, socket) do
    socket =
      assign(socket, user_id: socket.assigns.current_user_id, page: 1, per_page: 20)
      |> fetch()

    {:ok, socket, temporary_assigns: [latest_messages: []]}
  end

  defp fetch(%{assigns: %{user_id: user_id, page: page, per_page: per_page}} = socket) do
    assign(socket, latest_messages: Message.latest_by_user(user_id, page, per_page))
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> fetch()}
  end

  def render(assigns) do
    ~F"""
    <table class="m-4 border border-separate border-gray-lighter">
      <thead>
      <tr>
        <th class="hidden sm:table-cell">Type</th>
        <th>Creator</th>
        <th>Content</th>
        <th class="hidden sm:table-cell">Date</th>
      </tr>
      </thead>
      <tbody id="table-body-episodes"
             phx-update="append">
        {#for {message, index} <- @latest_messages |> Enum.with_index}
          <tr id={"message-#{message.id}"}
              class={"bg-gray-lighter": Integer.is_even(index)}>
            <td class="p-2 hidden sm:table-cell"><Pill type="success">{message.type}</Pill></td>
            <td class="p-2 nobr">{#if message.creator} {message.creator.name} {#else} {message.persona.name} {/if}</td>
            <td>{raw (message.content)}</td>
            <td class="p-2 hidden sm:table-cell whitespace-nowrap">
              {message.inserted_at |> Timex.format!("{ISOdate} {h24}:{m}:{s}")}
            </td>
          </tr>
        {/for}
      </tbody>
    </table>
    <div id="infinite-scroll" class="h-24" phx-hook="InfiniteScroll" data-page={@page}></div>
    """
  end
end
