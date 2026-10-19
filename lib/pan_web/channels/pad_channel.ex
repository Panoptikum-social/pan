defmodule PanWeb.PadChannel do
  @moduledoc """
  The Yjs sync of one pad between a browser (y-phoenix-channel) and its
  `PanWeb.PadServer`. Only followers of the pad's community may join. While
  the pad is read only, messages that would change the text are dropped
  here; cursors and the initial sync still pass.
  """
  use Phoenix.Channel

  alias Pan.Repo
  alias PanWeb.{Pad, PadServer}

  intercept(["read_only", "deleted"])

  @impl true
  def join("pad:" <> pad_id, _payload, socket) do
    with %Pad{} = pad <- Repo.get(Pad, pad_id),
         %{read: true} <- Pad.permissions(socket.assigns.user_id, pad.community_id),
         {:ok, server} <- PadServer.find_or_start(pad.id) do
      {:ok, %{read_only: pad.read_only}, start_observing(socket, server, pad)}
    else
      _ -> {:error, %{reason: "not found"}}
    end
  end

  @doc "Tells the open editors of a pad that it is now read only or editable again."
  def broadcast_read_only(%Pad{id: id, read_only: read_only}) do
    PanWeb.Endpoint.broadcast("pad:#{id}", "read_only", %{read_only: read_only})
  end

  @doc "Tells the open editors of a pad that it has been deleted."
  def broadcast_deleted(%Pad{id: id}) do
    PanWeb.Endpoint.broadcast("pad:#{id}", "deleted", %{})
  end

  defp start_observing(socket, server, pad) do
    :ok = PadServer.observe(server)
    Process.monitor(server)
    assign(socket, pad_id: pad.id, server: server, read_only: pad.read_only)
  end

  @impl true
  def handle_in(event, {:binary, message}, socket) when event in ["yjs", "yjs_sync"] do
    unless socket.assigns.read_only and changes_text?(message) do
      PadServer.process_message_v1(socket.assigns.server, message, self())
      |> push_replies(socket)
    end

    {:noreply, socket}
  end

  # y-protocols: sync step 2 (0, 1) and update (0, 2) carry document changes
  defp changes_text?(<<0, 1, _::binary>>), do: true
  defp changes_text?(<<0, 2, _::binary>>), do: true
  defp changes_text?(_message), do: false

  defp push_replies({:ok, replies}, socket) do
    Enum.each(replies, &push(socket, "yjs", {:binary, &1}))
  end

  defp push_replies(_result, _socket), do: :ok

  @impl true
  def handle_out("read_only", %{read_only: read_only} = payload, socket) do
    push(socket, "read_only", payload)
    {:noreply, assign(socket, read_only: read_only)}
  end

  def handle_out("deleted", payload, socket) do
    push(socket, "deleted", payload)
    {:stop, :normal, socket}
  end

  @impl true
  def handle_info({:yjs, message, _server}, socket) do
    push(socket, "yjs", {:binary, message})
    {:noreply, socket}
  end

  # the pad process stopped under us (it crashed, or stopped right as we
  # joined): start it again and let the browser sync anew
  def handle_info(
        {:DOWN, _ref, :process, server, _reason},
        %{assigns: %{server: server}} = socket
      ) do
    case PadServer.find_or_start(socket.assigns.pad_id) do
      {:ok, new_server} ->
        :ok = PadServer.observe(new_server)
        Process.monitor(new_server)
        push(socket, "yjs_resync", %{})
        {:noreply, assign(socket, server: new_server)}

      _error ->
        push(socket, "yjs_server_down", %{})
        {:stop, :normal, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket), do: {:noreply, socket}
end
