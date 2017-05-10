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
    whitelist_urls()
    respond_to_message(message, sender_id)
    conn
    |> send_resp(200, "ok")
  end

  def message(conn, _params) do
    conn
    |> send_resp(200, "ok")
  end

  defp respond_to_message(message, sender_id) do
    data = %{
      recipient: %{
        id: sender_id
      },
      message: message_response(podcasts_from_query(message))
    }
    |> Poison.encode!

    facebook_request_url("messages", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"])
  end

  defp podcasts_from_query(message) do
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

    from(p in Podcast, where: p.id in ^podcast_ids, preload: :episodes)
    |> Repo.all
  end

  defp whitelist_urls do
    body = %{
      setting_type: "domain_whitelisting",
      whitelisted_domains: [Application.get_env(:pan, :bot)[:host], "https://panoptikum.io/"],
      domain_action_type: "add"
    }
    |> Poison.encode!
    facebook_request_url("thread_settings", access_token_params())
    |> HTTPoison.post(body, ["Content-Type": "application/json"])
  end

  defp facebook_request_url(path, params) do
    "https://graph.facebook.com/v2.6/me/#{path}?#{params}"
  end

  defp access_token_params do
    %{
      access_token: Application.get_env(:pan, :bot)[:fb_access_token]
    }
    |> URI.encode_query()
  end

  defp message_response([]) do
    %{
      text: "Sorry! I couldn't find any podcasts with that. How about \"Serial\"?"
    }
  end

  defp message_response(podcasts) do
    %{
      attachment: %{
        type: "template",
        payload: %{
          template_type: "generic",
          elements: Enum.map(podcasts, &(podcast_json(&1)))
        }
      }
    }
  end

  defp podcast_json(podcast) do
    [episode | _rest] = podcast.episodes
    host = Application.get_env(:pan, :bot)[:host]
    %{
      title: podcast.title,
      image_url: podcast.image_url,
      subtitle: podcast.description,
      default_action: %{
        type: "web_url",
        url: host <> podcast_frontend_path(Pan.Endpoint, :show, podcast),
        messenger_extensions: true,
        webview_height_ratio: "tall",
        fallback_url: host <> podcast_frontend_path(Pan.Endpoint, :show, podcast)
      },
      buttons: [
        %{
          type: "web_url",
          url: host <> podcast_frontend_path(Pan.Endpoint, :show, podcast),
          title: "👉 Panoptikum"
        },
        %{
          type: "web_url",
          url: podcast.website,
          title: "🌎 Podcast website"
        },
        %{
          type: "web_url",
          url: host <> episode_frontend_path(Pan.Endpoint, :player, episode),
          messenger_extensions: true,
          webview_height_ratio: "tall",
          title: "🎧 Latest episode"
        }
      ]
    }
  end
end
