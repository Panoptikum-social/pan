defmodule Pan.BotController do
  use Pan.Web, :controller

  # To test using ngrok, call:
  #   $ ngrok http 4000

  def webhook(conn, %{ "hub.challenge" => challenge } ) do
    challenge = challenge
                |> String.to_integer()
    render conn, "webhook.json", challenge: challenge
  end

  def message(conn, %{"entry" => [%{"messaging" => [%{"message" => %{"text" => message}, "sender" => %{"id" => sender_id}}]}]}) do
    Pan.Bot.mark_as_read(sender_id)
    Pan.Bot.turn_typing_indicator_on(sender_id)
    Pan.Bot.whitelist_urls()
    Pan.Bot.respond_to_message(message, sender_id)
    Pan.Bot.turn_typing_indicator_off(sender_id)
    conn
    |> send_resp(200, "ok")
  end

  def message(conn, _params) do
    conn
    |> send_resp(200, "ok")
  end
end
