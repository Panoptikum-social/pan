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
    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment),
             search: [size: 5, from: 0,
               query: [
                 function_score: [
                   query: [match: [_all: [query: message]]],
                   boost_mode: "multiply",
                   functions: [
                     %{filter: [term: ["_type": "categories"]], weight: 0},
                     %{filter: [term: ["_type": "podcasts"]], weight: 1},
                     %{filter: [term: ["_type": "personas"]], weight: 0},
                     %{filter: [term: ["_type": "episodes"]], weight: 0},
                     %{filter: [term: ["_type": "users"]], weight: 0}]]]]]

    {:ok, 200, %{hits: hits, took: _took}} = Tirexs.Query.create_resource(query)

    podcast_ids = Enum.map(hits.hits, fn(hit) -> hit._id end)
    podcasts = from(p in Podcast, where: p.id in ^podcast_ids,
                                  preload: :episodes)
               |> Repo.all

    data = %{
      recipient: %{
        id: sender_id
      },
      message: message_response(conn, podcasts)
    }
    |> Poison.encode!

    params = %{
      access_token: Application.get_env(:pan, :bot)[:fb_access_token]
    }
    |> URI.encode_query()

    body = %{
      setting_type: "domain_whitelisting",
      whitelisted_domains: [Application.get_env(:pan, :bot)[:host], "https://panoptikum.io/"],
      domain_action_type: "add"
    }
    |> Poison.encode!
    "https://graph.facebook.com/v2.6/me/thread_settings?#{params}"
    |> HTTPoison.post(body, ["Content-Type": "application/json"])

    "https://graph.facebook.com/v2.6/me/messages?#{params}"
    |> HTTPoison.post(data, ["Content-Type": "application/json"])

    conn
    |> put_status(200)
    |> text("ok")
  end

  def message(conn, _params) do
    conn
    |> put_status(200)
    |> text("ok")
  end

  defp message_response(_conn, []) do
    %{
      text: "Sorry! I couldn't find any podcasts with that. How about \"Serial\"?"
    }
  end

  defp message_response(conn, podcasts) do
    %{
      attachment: %{
        type: "template",
        payload: %{
          template_type: "generic",
          elements: Enum.map(podcasts, &(podcast_json(conn, &1)))
        }
      }
    }
  end

  defp podcast_json(conn, podcast) do
    [episode | _rest] = podcast.episodes
    host = Application.get_env(:pan, :bot)[:host]
    %{
      title: podcast.title,
      image_url: podcast.image_url,
      subtitle: podcast.description,
      default_action: %{
        type: "web_url",
        url: host <> podcast_frontend_path(conn, :show, podcast),
        messenger_extensions: true,
        webview_height_ratio: "tall",
        fallback_url: host <> podcast_frontend_path(conn, :show, podcast)
      },
      buttons: [
        %{
          type: "web_url",
          url: host <> podcast_frontend_path(conn, :show, podcast),
          title: "👉 Panoptikum"
        },
        %{
          type: "web_url",
          url: podcast.website,
          title: "🌎 Podcast website"
        },
        %{
          type: "web_url",
          url: host <> episode_frontend_path(conn, :player, episode),
          messenger_extensions: true,
          webview_height_ratio: "tall",
          title: "🎧 Latest episode"
        }
      ]
    }
  end
end
