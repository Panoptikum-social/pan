defmodule PanWeb.PadServer do
  @moduledoc """
  One process per open pad, holding its Yjs document. The channels of the
  people editing it observe it: document and awareness (cursor) updates from
  one are sent on to all others.

  The preview, the text rendered with `PanWeb.ViewHelpers.markdown/1`, is
  sent as `{:preview, html}` to every observer at most every 300 ms while
  the text changes, and to each new observer right away.

  The Yjs state and a markdown copy of the text are saved a moment after the
  last edit and when the process stops, which it does a little while after
  the last observer has left (and on shutdown). Read only is enforced by
  `PanWeb.PadChannel`, before messages get here.
  """
  use Yex.DocServer

  alias Pan.Repo
  alias PanWeb.Pad
  alias Yex.{Awareness, Sync}

  import Ecto.Query, only: [from: 2]

  # the Y.Text holding the pad's markdown, shared with the browser
  @text "body"
  @save_after :timer.seconds(2)
  @preview_after 300
  @stop_after :timer.seconds(10)

  @doc "The running process of a pad, started if needed."
  def find_or_start(pad_id, attempts \\ 5) do
    case DynamicSupervisor.start_child(Pan.PadSupervisor, child_spec_for(pad_id)) do
      {:ok, pid} ->
        {:ok, pid}

      # a process that has just stopped stays registered for a moment
      {:error, {:already_started, pid}} ->
        cond do
          Process.alive?(pid) -> {:ok, pid}
          attempts > 0 -> retry_find_or_start(pad_id, attempts)
          true -> {:error, :still_stopping}
        end

      error ->
        error
    end
  end

  defp retry_find_or_start(pad_id, attempts) do
    Process.sleep(10)
    find_or_start(pad_id, attempts - 1)
  end

  defp child_spec_for(pad_id) do
    %{
      id: {__MODULE__, pad_id},
      start:
        {__MODULE__, :start_link,
         [[pad_id: pad_id], [name: {:via, Registry, {Pan.PadRegistry, pad_id}}]]},
      restart: :temporary
    }
  end

  def whereis(pad_id) do
    case Registry.lookup(Pan.PadRegistry, pad_id) do
      [{pid, _}] -> if Process.alive?(pid), do: pid
      [] -> nil
    end
  end

  @doc """
  Receive `{:yjs, message, server}` for every update from the others and
  `{:preview, html}` for the rendered text.
  """
  def observe(server), do: GenServer.call(server, {:observe, self()})

  def text_name, do: @text

  @impl true
  def init(option, %{doc: doc} = state) do
    # so that terminate/2 saves on shutdown, too
    Process.flag(:trap_exit, true)
    pad_id = Keyword.fetch!(option, :pad_id)

    case from(p in Pad, where: p.id == ^pad_id, select: p.yjs_state) |> Repo.one() do
      nil -> :ok
      yjs_state -> :ok = Yex.apply_update(doc, yjs_state)
    end

    {:ok,
     assign(state,
       pad_id: pad_id,
       observers: %{},
       awareness_clients: %{},
       dirty: false,
       save_timer: nil,
       preview_timer: nil,
       stop_timer: Process.send_after(self(), :stop_if_unobserved, @stop_after)
     )}
  end

  @impl true
  def handle_call({:observe, client}, _from, %{assigns: assigns} = state) do
    observers = Map.put_new_lazy(assigns.observers, client, fn -> Process.monitor(client) end)
    send(client, {:preview, preview(state)})
    {:reply, :ok, assign(state, observers: observers)}
  end

  @impl true
  def handle_update_v1(_doc, update, origin, state) do
    with {:ok, sync} <- Sync.get_update(update),
         {:ok, message} <- Sync.message_encode({:sync, sync}) do
      broadcast(message, origin, state)
    end

    {:noreply, state |> schedule_save() |> schedule_preview()}
  end

  @impl true
  def handle_awareness_update(
        awareness,
        %{removed: removed, added: added, updated: updated},
        origin,
        state
      ) do
    with {:ok, update} <- Awareness.encode_update(awareness, added ++ updated ++ removed),
         {:ok, message} <- Sync.message_encode({:awareness, update}) do
      broadcast(message, origin, state)
    end

    {:noreply, track_awareness_clients(state, origin, added, removed)}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, client, _reason}, %{assigns: assigns} = state) do
    # the cursors of a channel that went away vanish for the others
    Awareness.remove_states(state.awareness, Map.get(assigns.awareness_clients, client, []))

    state =
      assign(state,
        observers: Map.delete(assigns.observers, client),
        awareness_clients: Map.delete(assigns.awareness_clients, client)
      )

    if state.assigns.observers == %{} do
      {:noreply,
       assign(state, stop_timer: Process.send_after(self(), :stop_if_unobserved, @stop_after))}
    else
      {:noreply, state}
    end
  end

  def handle_info(:save, state), do: {:noreply, save(state)}

  def handle_info(:preview, %{assigns: %{observers: observers}} = state) do
    html = preview(state)
    for {client, _ref} <- observers, do: send(client, {:preview, html})
    {:noreply, assign(state, preview_timer: nil)}
  end

  def handle_info(:stop_if_unobserved, %{assigns: %{observers: observers}} = state)
      when observers == %{},
      do: {:stop, :normal, state}

  def handle_info(:stop_if_unobserved, state), do: {:noreply, state}

  def handle_info({:EXIT, _pid, reason}, state), do: {:stop, reason, state}

  @impl true
  def terminate(_reason, state) do
    save(state)
    :ok
  end

  defp broadcast(message, origin, %{assigns: %{observers: observers}}) do
    for {client, _ref} <- observers, client != origin do
      send(client, {:yjs, message, self()})
    end
  end

  defp track_awareness_clients(state, nil, _added, _removed), do: state

  defp track_awareness_clients(%{assigns: assigns} = state, origin, added, removed) do
    awareness_clients =
      Map.update(assigns.awareness_clients, origin, added, fn ids ->
        Enum.uniq(added ++ ids) -- removed
      end)

    assign(state, awareness_clients: awareness_clients)
  end

  defp schedule_save(%{assigns: %{save_timer: nil}} = state) do
    assign(state, dirty: true, save_timer: Process.send_after(self(), :save, @save_after))
  end

  defp schedule_save(state), do: assign(state, dirty: true)

  defp schedule_preview(%{assigns: %{preview_timer: nil}} = state) do
    assign(state, preview_timer: Process.send_after(self(), :preview, @preview_after))
  end

  defp schedule_preview(state), do: state

  defp preview(%{doc: doc}) do
    doc
    |> Yex.Doc.get_text(@text)
    |> Yex.Text.to_string()
    |> PanWeb.ViewHelpers.markdown(sourcepos: true)
    |> Phoenix.HTML.safe_to_string()
  end

  defp save(%{assigns: %{dirty: false}} = state), do: state

  defp save(%{doc: doc, assigns: assigns} = state) do
    {:ok, yjs_state} = Yex.encode_state_as_update(doc)
    markdown = doc |> Yex.Doc.get_text(@text) |> Yex.Text.to_string()

    # update_all: a pad deleted while open is simply not saved any more
    from(p in Pad, where: p.id == ^assigns.pad_id)
    |> Repo.update_all(
      set: [yjs_state: yjs_state, markdown: markdown, updated_at: NaiveDateTime.utc_now(:second)]
    )

    assign(state, dirty: false, save_timer: nil)
  end
end
