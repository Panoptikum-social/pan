defmodule Event do
  alias Pan.Repo
  alias Pan.Podcast
  alias Pan.Endpoint
  alias Pan.User
  alias Pan.Persona
  alias Pan.Category

  defstruct topic:           "",
            subtopic:        "",
            current_user_id: 0,
            user_id:         0,
            persona_id:      0,
            podcast_id:      0,
            category_id:     0,
            episode_id:      0,
            chapter_id:      0,
            content:         "",
            type:            "",
            event:           "",
            notification_text: ""


  def notify_subscribers(event) do
    notification = %{content: event.content,
                     type: event.type,
                     user_name: Repo.get(User, event.current_user_id).name}

    topics = [event.topic <> ":" <> event.subtopic] ++
             User.follower_mailboxes(event.user_id) ++
             Persona.follower_mailboxes(event.persona_id) ++
             Podcast.follower_mailboxes(event.podcast_id) ++
             Category.follower_mailboxes(event.category_id)

    for topic <- topics do
      Endpoint.broadcast topic, "notification", notification
    end
  end
end