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

  @required_fields ~w(url length type guid)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
