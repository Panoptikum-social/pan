defmodule Pan.Repo.Migrations.UniqueConstraintsForChaptersAndEnclosures do
  use Ecto.Migration

  def change do
    create unique_index(:chapters, [:start, :episode_id])
    create unique_index(:enclosures, [:url, :episode_id])
  end
end