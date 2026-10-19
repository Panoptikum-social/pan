defmodule PanWeb.PadTrialChannel do
  use Phoenix.Channel

  alias Yex.Sync.SharedDoc

  # One SharedDoc process per pad, found by name through Pan.PadRegistry. It
  # holds the Yjs document in memory only and stops when the last channel
  # leaves (auto_exit).
  @impl true
  def join("pad_trial:" <> pad_name, _payload, socket) do
    case start_shared_doc(pad_name) do
      {:ok, doc_pid} ->
        SharedDoc.observe(doc_pid)
        Process.monitor(doc_pid)
        {:ok, assign(socket, doc_pid: doc_pid, pad_name: pad_name)}

      {:error, reason} ->
        {:error, %{reason: inspect(reason)}}
    end
  end

  @impl true
  def handle_in(event, {:binary, message}, socket) when event in ["yjs", "yjs_sync"] do
    SharedDoc.send_yjs_message(socket.assigns.doc_pid, message)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:yjs, message, _doc_pid}, socket) do
    push(socket, "yjs", {:binary, message})
    {:noreply, socket}
  end

  def handle_info(
        {:DOWN, _ref, :process, doc_pid, _reason},
        %{assigns: %{doc_pid: doc_pid}} = socket
      ) do
    case start_shared_doc(socket.assigns.pad_name) do
      {:ok, new_pid} ->
        SharedDoc.observe(new_pid)
        Process.monitor(new_pid)
        push(socket, "yjs_resync", %{})
        {:noreply, assign(socket, doc_pid: new_pid)}

      {:error, _reason} ->
        push(socket, "yjs_server_down", %{})
        {:stop, :shared_doc_down, socket}
    end
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, socket), do: {:noreply, socket}

  defp start_shared_doc(pad_name) do
    case SharedDoc.start([doc_name: pad_name],
           name: {:via, Registry, {Pan.PadRegistry, pad_name}}
         ) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end
end
