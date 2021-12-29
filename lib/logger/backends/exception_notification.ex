defmodule Logger.Backends.ExceptionNotification do
  @behaviour :gen_event

  require Logger

  def init(args), do: {:ok, args}

  def handle_event({:error, _group_leader, {Logger, message, timestamp, metadata}}, state) do
    old_metadata_format = Keyword.drop(metadata, [:error_logger])

    unless String.contains?(inspect(message), [
             "Fatal error: handshake failure",
             "Warning: unrecognised name",
             ":whitespace_required_between_attributes",
             ":unexpected_end"
           ]) do
      Logger.Formatter.compile("$time $metadata[$level] $message\n")
      |> Logger.Formatter.format(:error, message, timestamp, old_metadata_format)
      |> IO.chardata_to_string()
      |> Pan.Email.error_notification(
        "exeception_notification@panoptikum.io",
        "stefan@panoptikum.io"
      )
      |> Pan.Mailer.deliver_now!
    end

    {:ok, state}
  end

  def handle_event({_level, group_leader, {Logger, _, _, _}}, state)
      when node(group_leader) != node(),
      do: {:ok, state}

  def handle_event({level, _group_leader, {Logger, _, _, _}}, state)
      when level in [:debug, :info, :warn],
      do: {:ok, state}

  def handle_call({:configure, new_keys}, _state), do: {:ok, :ok, new_keys}
  def handle_call(request, _state), do: exit({:bad_call, request})

  def handle_info(_msg, state), do: {:ok, state}

  def code_change(_old_vsn, state, _extra), do: {:ok, state}

  def terminate(_reason, _state), do: :ok
end
