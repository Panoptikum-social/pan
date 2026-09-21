defmodule Pan.Mailer do
  use Swoosh.Mailer, otp_app: :pan
  require Logger

  # Delivery reports for mail we could not deliver go to this address (an alias
  # of the `bounce@` mailbox, with our SMTP login as permitted sender). Swoosh's
  # SMTP adapter uses the "Sender" header as the envelope sender, so From stays
  # whatever the email says.
  @bounce_address "bounces@panoptikum.social"

  # Error notification mails are sent from a Logger backend: a failure to send
  # them must not log an error or write to the database, or it would trigger
  # another notification.
  @notification_sender "robot@informatom.com"

  def deliver(email, config \\ [])

  def deliver(email, config) do
    email
    |> Swoosh.Email.header("Sender", @bounce_address)
    |> super(config)
    |> report(email)
  end

  # The relay only reports a nonexistent address later, as a bounce mail, so
  # what we learn here are refusals by the relay itself. On success the receipt
  # holds the relay's queue id, which is also in the bounce report.
  defp report({:ok, receipt} = result, email) do
    Logger.info("mail to #{recipients(email)} sent: #{inspect(receipt)}")
    result
  end

  defp report({:error, reason} = result, %{from: {_name, @notification_sender}} = email) do
    Logger.warning("mail to #{recipients(email)} failed: #{inspect(reason)}")
    result
  end

  defp report({:error, reason} = result, email) do
    Logger.warning("mail to #{recipients(email)} failed: #{inspect(reason)}")

    PanWeb.Journal.log(%{
      module: __MODULE__,
      method: "deliver",
      text: "mail to #{recipients(email)} failed, subject: #{email.subject}",
      after: reason
    })

    result
  end

  defp recipients(email), do: Enum.map_join(email.to, ", ", fn {_name, address} -> address end)
end
