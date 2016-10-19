defmodule Pan.Language do
  use Pan.Web, :model

  schema "languages" do
    field :shortcode, :string
    field :name, :string
    timestamps

    has_many :podcasts, Pan.Podcast
  end

  @required_fields ~w(shortcode name)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:shortcode)
  end
end
