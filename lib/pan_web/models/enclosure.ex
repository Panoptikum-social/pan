defmodule PanWeb.Enclosure do
  use PanWeb, :model

  schema "enclosures" do
    field(:url, :string)
    field(:length, :string)
    field(:type, :string)
    field(:guid, :string)
    belongs_to(:episode, PanWeb.Episode)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :length, :type, :guid])
    |> validate_required([:url, :type, :guid])
  end
end
