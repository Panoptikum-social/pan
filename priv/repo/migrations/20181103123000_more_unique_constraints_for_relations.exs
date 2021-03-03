defmodule Pan.Repo.Migrations.UniqueConstraintsForRelations do
  use Ecto.Migration

  def change do
    create(unique_index(:categories_podcasts, [:podcast_id, :category_id]))
    create(unique_index(:languages_podcasts, [:podcast_id, :language_id]))
  end
end
