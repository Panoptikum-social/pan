defmodule Pan.ExceptionNotificationTest do
  use ExUnit.Case, async: true

  alias Pan.ExceptionNotification

  setup do
    {:ok, config} = ExceptionNotification.adding_handler(%{level: :error})
    %{config: config}
  end

  defp event(message, meta \\ %{}) do
    %{
      level: :error,
      msg: {:string, message},
      meta: Map.merge(%{time: :logger.timestamp(), gl: Process.group_leader()}, meta)
    }
  end

  # the mail is sent from a Task, Swoosh's test adapter reports to its caller
  test "an error is mailed", %{config: config} do
    assert :ok = ExceptionNotification.log(event("Something broke"), config)

    assert_receive {:email, %Swoosh.Email{subject: subject, text_body: body}}, 1000
    assert subject =~ "Error Notification"
    assert body =~ "[error] Something broke"
  end

  test "known noise is not mailed", %{config: config} do
    ExceptionNotification.log(event("TLS: Fatal error: handshake failure"), config)
    refute_receive {:email, _}, 200
  end

  test "errors from sending a mail are not mailed again", %{config: config} do
    # what deliver/1 marks the mail process with
    Process.put(:pan_exception_notification_sending, true)
    ExceptionNotification.log(event("relay said no"), config)
    refute_receive {:email, _}, 200
  end

  test "a broken event doesn't raise, :logger would drop the handler", %{config: config} do
    assert :ok = ExceptionNotification.log(%{meta: %{}, msg: :nonsense}, config)
  end
end
