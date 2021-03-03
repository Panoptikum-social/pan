defmodule Pan.Repo.Migrations.RemoveUniqueGuidIndexFromPodcasts do
  use Ecto.Migration

  def up do
    drop(unique_index(:episodes, [:guid]))
    create(index(:episodes, [:guid]))
  end

  def down do
    create(unique_index(:episodes, [:guid]))
    drop(index(:episodes, [:guid]))
  end
end
