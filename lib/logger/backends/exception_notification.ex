defmodule Logger.Backends.ExceptionNotification do
  use GenServer

  def handle_cast({:error, _group_leader, {Logger, message, timestamp, metadata}}, state) do
    unless String.contains?(inspect(message), ["Fatal error: handshake failure",
                                               "Warning: unrecognised name",
                                               ":unexpected_end"]) do
      Logger.Formatter.compile("$time $metadata[$level] $message\n")
      |> Logger.Formatter.format(:error, message, timestamp, metadata)
      |> IO.iodata_to_binary
      |> Pan.Email.error_notification("exeception_notification@panoptikum.io",
                                      "stefan@panoptikum.io")
      |> Pan.Mailer.deliver_now()
    end

    {:noreply, state}
  end

  def handle_cast({_level, group_leader, {Logger, _, _, _}}, state)
    when node(group_leader) != node(), do: {:noreply, state}

  def handle_cast({level, _group_leader, {Logger, _, _, _}}, state)
    when level in [:debug, :info, :warn], do: {:noreply, state}
end
