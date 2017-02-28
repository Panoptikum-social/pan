defmodule Pan.Language do
  use Pan.Web, :model

  @required_fields ~w(shortcode name)
  @optional_fields ~w()

  schema "languages" do
    field :shortcode, :string
    field :name, :string
    timestamps()

    many_to_many :podcasts, Pan.Podcast, join_through: "languages_podcasts"
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:shortcode)
  end
end
