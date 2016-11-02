defmodule Pan.Repo.Migrations.RemoveUniqueWebsiteIndexFromPodcasts do
  use Ecto.Migration

  def up do
    drop unique_index(:podcasts, [:website])
    create index(:podcasts, [:website])
  end

  def down do
    create unique_index(:podcasts, [:website])
    drop index(:podcasts, [:website])
  end
end
