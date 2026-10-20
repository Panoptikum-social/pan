defmodule Pan.Search.ReflagQueue do
  @moduledoc """
  Re-flags podcasts and all their episodes for `Pan.Job.PushMissingSearchIndex`
  (`full_text: false`), e.g. after a category merge or rename, as their search
  docs carry copies of the categories.

  One process for all requests, working through them a chunk of podcasts at
  a time with a short pause in between: at most one database connection, and
  each UPDATE is short. Starting one task per merge, each updating all
  episodes of a category in one statement, had several of them block each
  other on the same rows (podcasts sit in several categories), every one
  holding a pool connection until the pool was exhausted.

  Ids queued twice are done once. On a database error the chunk is retried
  later; pending ids are lost when the process restarts. In test, chunks are
  only worked on by `flush/0` (`config :pan, Pan.Search.ReflagQueue, manual: true`).
  """
  use GenServer
  import Ecto.Query, only: [from: 2]
  require Logger
  alias Pan.Repo
  alias PanWeb.{Episode, Podcast}

  @chunk 100
  @pause 50
  @retry_after :timer.seconds(10)

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def add(podcast_ids), do: GenServer.cast(__MODULE__, {:add, podcast_ids})

  @doc "Works through everything queued, then returns."
  def flush, do: GenServer.call(__MODULE__, :flush, :infinity)

  @impl true
  def init(nil) do
    manual = Application.get_env(:pan, __MODULE__, [])[:manual] || false
    {:ok, %{pending: MapSet.new(), done: 0, manual: manual}}
  end

  @impl true
  def handle_cast({:add, podcast_ids}, %{pending: pending} = state) do
    # a chunk is already scheduled while anything is pending
    if MapSet.size(pending) == 0 and not state.manual, do: send(self(), :work)
    {:noreply, %{state | pending: MapSet.union(pending, MapSet.new(podcast_ids))}}
  end

  @impl true
  def handle_info(:work, state) do
    case work_chunk(state) do
      {:ok, state} ->
        if MapSet.size(state.pending) > 0, do: Process.send_after(self(), :work, @pause)
        {:noreply, log_done(state)}

      {:error, state} ->
        Process.send_after(self(), :work, @retry_after)
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:flush, _from, state), do: {:reply, :ok, drain(state)}

  # stops at a database error, leaving the rest pending
  defp drain(state) do
    case work_chunk(state) do
      {:ok, state} -> if MapSet.size(state.pending) > 0, do: drain(state), else: log_done(state)
      {:error, state} -> state
    end
  end

  defp work_chunk(%{pending: pending} = state) do
    ids = Enum.take(pending, @chunk)

    from(p in Podcast, where: p.id in ^ids) |> Repo.update_all(set: [full_text: false])

    from(e in Episode, where: e.podcast_id in ^ids)
    |> Repo.update_all([set: [full_text: false]], timeout: :infinity)

    {:ok,
     %{
       state
       | pending: MapSet.difference(pending, MapSet.new(ids)),
         done: state.done + length(ids)
     }}
  rescue
    exception ->
      Logger.warning("Re-flagging for search failed, retrying: #{Exception.message(exception)}")
      {:error, state}
  end

  # once the queue is empty
  defp log_done(%{done: 0} = state), do: state

  defp log_done(state) do
    if MapSet.size(state.pending) > 0, do: state, else: log_and_reset(state)
  end

  defp log_and_reset(state) do
    Logger.info("Re-flagged #{state.done} podcasts and their episodes for search")
    %{state | done: 0}
  end
end
