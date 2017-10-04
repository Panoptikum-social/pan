defmodule Pan.Bot do
  use Pan.Web, :controller
  alias PanWeb.Podcast

  def whitelist_urls do
    body = %{
      setting_type: "domain_whitelisting",
      whitelisted_domains: [Application.get_env(:pan, :bot)[:host], "https://panoptikum.io/"],
      domain_action_type: "add"
    }
    |> Poison.encode!
    facebook_request_url("thread_settings", access_token_params())
    |> HTTPoison.post(body, ["Content-Type": "application/json"], stream_to: self())
  end

  def setup_call_to_action do
    data = %{
      setting_type: "call_to_actions",
      thread_state: "new_thread",
      call_to_actions: [
        %{
          payload: "GREETING_ACTION"
        }
      ]
    }
    |> Poison.encode!

    facebook_request_url("thread_settings", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"], stream_to: self())
  end

  def greet_user(sender_id) do
    data = %{
      recipient: %{
        id: sender_id
      },
      message: %{
        text: "Hey there! I'll send you podcasts related to whatever you tell me. Give it a try!"
      }
    }
    |> Poison.encode!

    facebook_request_url("messages", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"], stream_to: self())
  end

  def set_greeting(message) do
    data = %{
      setting_type: "greeting",
      greeting: %{
        text: message
      }
    }
    |> Poison.encode!

    facebook_request_url("thread_settings", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"], stream_to: self())
  end

  def mark_as_read(sender_id) do
    send_action(sender_id, "mark_seen")
  end

  def turn_typing_indicator_on(sender_id) do
    send_action(sender_id, "typing_on")
  end

  def turn_typing_indicator_off(sender_id) do
    send_action(sender_id, "typing_off")
  end

  def respond_to_message(message, sender_id) do
    data = %{
      recipient: %{
        id: sender_id
      },
      message: message_response(podcasts_from_query(message))
    }
    |> Poison.encode!

    facebook_request_url("messages", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"], stream_to: self())
  end

  defp podcasts_from_query(message) do
    query = [index: "/panoptikum_" <> Application.get_env(:pan, :environment) <> "/podcasts",
             search: [size: 5, from: 0, query: [match: [_all: params["filter"]]]]]

    {:ok, 200, %{hits: hits, took: _took}} = Tirexs.Query.create_resource(query)

    podcast_ids = Enum.map(hits.hits, fn(hit) -> hit._id end)

    from(p in Podcast, where: p.id in ^podcast_ids, preload: :episodes)
    |> Pan.Repo.all
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
    data = %{
      title: podcast.title,
      subtitle: podcast.description,
      default_action: %{
        type: "web_url",
        url: host <> podcast_frontend_path(PanWeb.Endpoint, :show, podcast),
        messenger_extensions: true,
        webview_height_ratio: "tall",
        fallback_url: host <> podcast_frontend_path(PanWeb.Endpoint, :show, podcast)
      },
      buttons: [
        %{
          type: "web_url",
          url: host <> podcast_frontend_path(PanWeb.Endpoint, :show, podcast),
          title: "👉 Panoptikum"
        },
        %{
          type: "web_url",
          url: podcast.website,
          title: "🌎 Podcast website"
        },
        %{
          type: "web_url",
          url: host <> episode_frontend_path(PanWeb.Endpoint, :player, episode),
          messenger_extensions: true,
          webview_height_ratio: "tall",
          title: "🎧 Latest episode"
        }
      ]
    }
    case podcast.image_url && URI.parse(podcast.image_url).scheme do
      nil -> data
      _ ->
        Map.put_new(data, :image_url, podcast.image_url)
    end
  end

  defp send_action(sender_id, action) do
    data = %{
      recipient: %{
        id: sender_id
      },
      sender_action: action
    }
    |> Poison.encode!

    facebook_request_url("messages", access_token_params())
    |> HTTPoison.post(data, ["Content-Type": "application/json"], stream_to: self())
  end
end
