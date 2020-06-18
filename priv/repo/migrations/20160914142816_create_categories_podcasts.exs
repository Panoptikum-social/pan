defmodule Pan.Repo.Migrations.CreateCategoriesPodcasts do
  use Ecto.Migration

  def change do
    create table(:categories_podcasts, primary_key: false) do
      add(:category_id, references(:categories))
      add(:podcast_id, references(:podcasts))
    end
  end
end
