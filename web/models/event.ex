defmodule Event do
  use Pan.Web, :channel
  alias Pan.Repo
  alias Pan.Podcast
  alias Pan.Endpoint
  alias Pan.User

  defstruct topic:           "",
            subtopic:        "",
            current_user_id: 0,
            user_id:         0,
            podcast_id:      0,
            category_id:     0,
            episode_id:      0,
            content:         "",
            type:            "",
            event:           ""


  def notify_subscribers(event) do
    notification = %{content: event.content,
                     type: event.type,
                     user_name: Repo.get(User, event.current_user_id).name}

    follower_mailboxes = Podcast.follower_mailboxes(event.podcast_id)

    topics = [event.topic <> ":" <> event.subtopic | follower_mailboxes]

    for topic <- topics do
      Endpoint.broadcast topic, "notification", notification
    end
  end
end