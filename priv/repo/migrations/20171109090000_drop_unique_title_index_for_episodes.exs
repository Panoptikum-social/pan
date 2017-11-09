defmodule Pan.Repo.Migrations.DropUniqueTitleIndexForEpisodes do
  use Ecto.Migration

  def change do
    drop unique_index(:episodes, [:title, :podcast_id])
  end
end