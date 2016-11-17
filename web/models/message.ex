defmodule Pan.Message do
  use Pan.Web, :model

  schema "messages" do
    field :content, :string
    field :type, :string
    field :topic, :string
    field :subtopic, :string
    field :event, :string
    belongs_to :creator, Pan.Creator

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
end
