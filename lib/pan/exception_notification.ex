defmodule Pan.ExceptionNotification do
  @moduledoc """
  An Erlang `:logger` handler mailing every error (and worse) to the admins.
  Prod only: configured as `config :pan, :logger` in config/prod.exs and
  added by `Logger.add_handlers(:pan)` in `Pan.Application`.

  `:logger` calls `log/2` in the process that logs, and removes a handler
  for good once it raises. So the mail goes out from a separate process and
  any failure in here is swallowed. Errors logged while a mail is being sent
  are not mailed again.
  """

  @address "robot@informatom.com"
  @sending :pan_exception_notification_sending

  # known noise, not worth a mail
  @ignored [
    "Fatal error: handshake failure",
    "Warning: unrecognised name",
    ":whitespace_required_between_attributes",
    ":unexpected_end",
    ":unrecognized name"
  ]

  def adding_handler(config) do
    {Logger.Formatter, formatter} =
      Logger.Formatter.new(format: "$time $metadata[$level] $message\n", metadata: :all)

    {:ok, Map.put(config, :config, %{formatter: formatter})}
  end

  def log(%{meta: meta} = event, %{config: %{formatter: formatter}}) do
    text = event |> Logger.Formatter.format(formatter) |> IO.chardata_to_string()
    if mail?(meta, text), do: Task.start(fn -> deliver(text) end)
    :ok
  rescue
    _exception -> :ok
  end

  # not from a remote console's group leader, not logged while a mail is
  # being sent (log/2 runs in the logging process), not known noise
  defp mail?(meta, text) do
    local?(meta) and !Process.get(@sending) and !String.contains?(text, @ignored)
  end

  defp local?(%{gl: group_leader}), do: node(group_leader) == node()
  defp local?(_meta), do: true

  defp deliver(text) do
    Process.put(@sending, true)

    text
    |> Pan.Email.error_notification(@address, @address)
    |> Pan.Mailer.deliver()
  end
end
