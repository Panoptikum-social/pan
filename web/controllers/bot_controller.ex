defmodule Pan.BotController do
  use Pan.Web, :controller
  alias Pan.Podcast

  # To test using ngrok, call:
  #   $ ngrok http 4000

  def webhook(conn, %{ "hub.challenge" => challenge } ) do
    challenge = challenge
                |> String.to_integer()
    render conn, "webhook.json", challenge: challenge
  end

  def message(conn, %{"entry" => [%{"messaging" => [%{"message" => %{"text" => message}, "sender" => %{"id" => sender_id}}]}]}) do
    sqlfrag = "%" <> message <> "%"
    podcasts = from(p in Podcast, where: ilike(p.title,       ^sqlfrag) or
                                         ilike(p.description, ^sqlfrag) or
                                         ilike(p.summary,     ^sqlfrag) or
                                         ilike(p.author,      ^sqlfrag),
                                  limit: 5)
                  |> Repo.all()
    data = %{
      recipient: %{
        id: sender_id
      },
      message: %{
        attachment: %{
          type: "template",
          payload: %{
            template_type: "generic",
            elements: Enum.map(podcasts, &(podcast_json(conn, &1)))
          }
        }
      }
    }
    |> Poison.encode!

    params = %{
      access_token: Application.get_env(:pan, :bot)[:fb_access_token]
    }
    |> URI.encode_query()

    body = %{
      setting_type: "domain_whitelisting",
      whitelisted_domains: ["https://20ba4076.ngrok.io"],
      domain_action_type: "add"
    }
    |> Poison.encode!
    "https://graph.facebook.com/v2.6/me/thread_settings?#{params}"
    |> HTTPotion.post([body: body,  headers: ["Content-Type": "application/json"]])

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

  defp podcast_json(conn, podcast) do
    %{
      title: podcast.title,
      image_url: podcast.image_url,
      subtitle: podcast.description,
      default_action: %{
        type: "web_url",
        url: "https://20ba4076.ngrok.io" <> podcast_frontend_path(conn, :show, podcast),
        messenger_extensions: true,
        webview_height_ratio: "tall",
        fallback_url: "https://20ba4076.ngrok.io" <> podcast_frontend_path(conn, :show, podcast)
      },
      buttons: [
        %{
          type: "web_url",
          url: "https://20ba4076.ngrok.io" <> podcast_frontend_path(conn, :show, podcast),
          title: "In Panoptikum"
        },
        %{
          type: "web_url",
          url: "https://20ba4076.ngrok.io" <> podcast_frontend_path(conn, :show, podcast),
          title: "View Website"
        }
      ]
    }
  end
end
