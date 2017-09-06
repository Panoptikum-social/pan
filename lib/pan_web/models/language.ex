defmodule PanWeb.Language do
  use Pan.Web, :model

  schema "languages" do
    field :shortcode, :string
    field :name, :string
    field :emoji, :string
    timestamps()

    many_to_many :podcasts, PanWeb.Podcast, join_through: "languages_podcasts"
  end


  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:shortcode, :name, :emoji])
    |> validate_required([:shortcode, :name])
    |> unique_constraint(:shortcode)
  end
end