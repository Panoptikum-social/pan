defmodule Pan.Repo.Migrations.RemoveUnusedIndices do
  use Ecto.Migration

  def up do
    drop(index(:episodes, [:guid]))
    drop(index(:episodes, [:podcast_id, :id]))
    drop(index(:gigs, ["publishing_date DESC NULLS LAST"]))
  end

  def down do
    create(index(:episodes, [:guid]))
    create(index(:episodes, [:podcast_id, :id]))
    create(index(:gigs, ["publishing_date DESC NULLS LAST"]))
  end
end
