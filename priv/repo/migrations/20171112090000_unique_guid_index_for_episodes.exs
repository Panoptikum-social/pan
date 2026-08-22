defmodule Pan.Repo.Migrations.UniqueGuidIndexForEpisodes do
  use Ecto.Migration

  def change do
    create(unique_index(:episodes, [:guid, :podcast_id]))
  end
end
