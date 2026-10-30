defmodule Pan.Repo.Migrations.AddSlugToCommunities do
  use Ecto.Migration
  import Ecto.Query

  # The community's address instead of its id (#483), made from the title
  # like a pad's slug and changing along with it.
  def up do
    alter table(:communities) do
      add(:slug, :string)
    end

    flush()

    for {id, title} <- repo().all(from(c in "communities", select: {c.id, c.title})) do
      from(c in "communities", where: c.id == ^id)
      |> repo().update_all(set: [slug: PanWeb.Pad.slugify(title)])
    end

    create(unique_index(:communities, [:slug]))
  end

  def down do
    alter table(:communities) do
      remove(:slug)
    end
  end
end
