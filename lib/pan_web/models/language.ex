defmodule PanWeb.Language do
  use PanWeb, :model

  alias Pan.Repo
  alias PanWeb.Language

  schema "languages" do
    field(:shortcode, :string)
    field(:name, :string)
    field(:emoji, :string)
    timestamps()

    many_to_many(:podcasts, PanWeb.Podcast, join_through: "languages_podcasts")
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:shortcode, :name, :emoji])
    |> validate_required([:shortcode, :name])
    |> unique_constraint(:shortcode)
  end

  def get_by_category_id(category_id) do
    from(l in Language,
      right_join: p in assoc(l, :podcasts),
      join: c in assoc(p, :categories),
      where: c.id == ^category_id,
      distinct: [asc: l.name],
      select: %{name: l.name, emoji: l.emoji}
    )
    |> Repo.all()
  end
end
