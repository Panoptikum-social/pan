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
    sqlfrag = "%" <> message <> "%"
    podcast_ids = from(p in Pan.Podcast, where: ilike(p.title, ^sqlfrag),
                                      select: p.id)
                |> Repo.all()

    users_also_liking = from(l in Pan.Like, where: l.podcast_id in ^podcast_ids and
                                               is_nil(l.chapter_id) and
                                               is_nil(l.episode_id),
                                        select: l.enjoyer_id)
                        |> Repo.all()
                        |> Enum.uniq
    also_liked = from(l in Pan.Like, join: p in assoc(l, :podcast),
                                 where: l.enjoyer_id in ^users_also_liking and
                                        is_nil(l.chapter_id) and
                                        is_nil(l.episode_id) and
                                        not(l.podcast_id in ^podcast_ids),
                                 group_by: p.id,
                                 select: [count(l.podcast_id), p.id, p.title],
                                 order_by: [desc: count(l.podcast_id)],
                                 limit: 10)
                 |> Repo.all()
    reply = case also_liked do
      [[_, _, title] | _] ->
        title
      [] ->
        "No matches found"
    end

    data = %{
      recipient: %{
        id: sender_id
      },
      message: %{
        text: reply
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
