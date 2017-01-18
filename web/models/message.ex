defmodule Pan.Message do
  use Pan.Web, :model
  alias Pan.Message
  alias Pan.Repo

  schema "messages" do
    field :content, :string
    field :type, :string
    field :topic, :string
    field :subtopic, :string
    field :event, :string
    belongs_to :creator, Pan.User
    belongs_to :persona, Pan.Persona

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:content, :type, :topic, :subtopic, :event])
    |> validate_required([:content, :type, :topic, :subtopic, :event])
  end


  def persist_event(event) do
    %Message{topic: event.topic,
             subtopic: event.subtopic,
             event: event.event,
             content: event.content,
             creator_id: event.current_user_id,
             type: event.type}
    |> Repo.insert
  end
end
