defmodule Pan.Repo.Migrations.CreateLanguagesPodcasts do
  use Ecto.Migration

  def change do
    create table(:languages_podcasts, primary_key: false) do
      add :language_id, references(:languages)
      add :podcast_id, references(:podcasts)
    end
  end

  def up do
    alter table(:podcasts) do
      remove :language_id
    end
    drop index(:podcasts, [:language_id])
  end

  def down do
    alter table(:podcasts) do
      add :language_id, :integer
    end
    create index(:podcasts, [:language_id])
  end
end
