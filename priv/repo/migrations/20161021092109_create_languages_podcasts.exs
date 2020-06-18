defmodule Pan.Repo.Migrations.CreateLanguagesPodcasts do
  use Ecto.Migration

  def change do
    create table(:languages_podcasts, primary_key: false) do
      add(:language_id, references(:languages))
      add(:podcast_id, references(:podcasts))
    end
  end
end
