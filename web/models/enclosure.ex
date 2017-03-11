defmodule Pan.Enclosure do
  use Pan.Web, :model

  schema "enclosures" do
    field :url, :string
    field :length, :string
    field :type, :string
    field :guid, :string
    belongs_to :episode, Pan.Episode

    timestamps()
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :length, :type, :guid])
    |> validate_required([:url, :type, :guid])
  end
end
