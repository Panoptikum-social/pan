defmodule Pan.Job.SendRetentionNotices do
  use GenServer
  require Logger

  # One notice every five minutes keeps the mail rate low (at most 288 a day)
  # and works through the backlog within a few days.
  @interval 5 * 60 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  # The state holds the ids of users whose notice could not be sent, so one
  # refused address doesn't block the queue. It is emptied on a restart.
  @impl true
  def init(failed_ids) do
    # give app three quiet minutes in the beginning
    Process.send_after(self(), :work, 3 * 60 * 1000)
    {:ok, failed_ids}
  end

  @impl true
  def handle_info(:work, failed_ids) do
    Process.send_after(self(), :work, @interval)

    case PanWeb.User.next_retention_candidate_id(failed_ids) do
      nil ->
        {:noreply, failed_ids}

      id ->
        case PanWeb.User.send_retention_notices([id]) do
          %{sent: 1} -> {:noreply, failed_ids}
          _ -> {:noreply, [id | failed_ids]}
        end
    end
  end

  # See Pan.Job.RefreshPodcastMetadata's handle_info/2 catch-all: stray
  # hackney messages can land here after a call.
  @impl true
  def handle_info(message, failed_ids) do
    Logger.warning("SendRetentionNotices received unexpected message: #{inspect(message)}")
    {:noreply, failed_ids}
  end
end
