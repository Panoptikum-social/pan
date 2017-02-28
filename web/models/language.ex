defmodule Pan.Language do
  use Pan.Web, :model

  schema "languages" do
    field :shortcode, :string
    field :name, :string
    timestamps()

    many_to_many :podcasts, Pan.Podcast, join_through: "languages_podcasts"
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:shortcode, :name])
    |> validate_required([:shortcode, :name])
    |> unique_constraint(:shortcode)
  end
end