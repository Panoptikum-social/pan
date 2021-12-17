defmodule PanWeb.Message do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.{Message, User}

  schema "messages" do
    field(:content, :string)
    field(:type, :string)
    field(:topic, :string)
    field(:subtopic, :string)
    field(:event, :string)
    belongs_to(:creator, PanWeb.User)
    belongs_to(:persona, PanWeb.Persona)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content, :type, :topic, :subtopic, :event, :persona_id, :creator_id])
    |> validate_required([:content, :type, :topic, :subtopic, :event])
  end

  def persist_event(event) do
    %Message{
      topic: event.topic,
      subtopic: event.subtopic,
      event: event.event,
      content: event.content,
      creator_id: event.current_user_id,
      type: event.type
    }
    |> Repo.insert()
  end

  def latest_by_user(user_id, page, per_page) do
    subscribed_user_ids = User.subscribed_user_ids(user_id)
    subscribed_category_ids = User.subscribed_category_ids(user_id)
    subscribed_podcast_ids = User.subscribed_podcast_ids(user_id)

    from(m in Message,
      where:
        (m.topic == "mailboxes" and m.subtopic == ^Integer.to_string(user_id)) or
          (m.topic == "users" and m.subtopic in ^subscribed_user_ids) or
          (m.topic == "podcasts" and m.subtopic in ^subscribed_podcast_ids) or
          (m.topic == "category" and m.subtopic in ^subscribed_category_ids),
      order_by: [desc: :inserted_at],
      preload: [:creator, :persona],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def created_by_user(user_id, page, per_page) do
    from(m in Message,
      where: m.creator_id == ^user_id,
      order_by: [desc: :inserted_at],
      preload: :creator,
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def get_by_persona_ids(persona_ids, page, per_page) do
    from(m in Message,
      where: m.persona_id in ^persona_ids,
      order_by: [desc: :inserted_at],
      preload: [:persona, :creator],
      limit: ^per_page,
      offset: (^page - 1) * ^per_page
    )
    |> Repo.all()
  end

  def count_by_persona_id(persona_id) do
    from(r in Message, where: r.persona_id == ^persona_id)
    |> Repo.aggregate(:count)
  end
end
