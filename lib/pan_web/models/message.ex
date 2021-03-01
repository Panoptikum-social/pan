defmodule PanWeb.Message do
  use PanWeb, :model
  alias Pan.Repo
  alias PanWeb.Message

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
    |> cast(params, [:content, :type, :topic, :subtopic, :event])
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
end
