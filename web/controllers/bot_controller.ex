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
    data = %{
      recipient: %{
        id: sender_id
      },
      message: %{
        text: message
      }
    }
    |> Poison.encode!

    params = %{
      access_token: Application.get_env(:pan, :bot)[:fb_access_token]
    }
    |> URI.encode_query()

    "https://graph.facebook.com/v2.6/me/messages?#{params}"
    |> HTTPotion.post([body: data,  headers: ["Content-Type": "application/json"]])

    conn
    |> put_status(200)
    |> text("ok")
  end

  def message(conn, _params) do
    conn
    |> put_status(200)
    |> text("ok")
  end
end
