defmodule Pan.Job.UserProExpiration do
  use GenServer
  import Pan.Parser.MyDateTime, only: [now: 0]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  defp seconds_to_wait() do
    86_400 - NaiveDateTime.diff(now(),  %{now() | hour: 6, minute: 0, second: 0})
  end

  @impl true
  def init(state) do
    # search for Users to be expired tomorrow morning 06:00
    Process.send_after(self(), :work, seconds_to_wait() * 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    PanWeb.User.pro_expiration
    # search for Users to be expired tomorrow morning 06:00
    Process.send_after(self(), :work, seconds_to_wait() * 1000)
    {:noreply, state}
  end
end
