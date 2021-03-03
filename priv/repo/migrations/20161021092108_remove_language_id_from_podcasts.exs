defmodule Pan.Repo.Migrations.RemoveLanguageIdFromPodcasts do
  use Ecto.Migration

  def up do
    drop(index(:podcasts, [:language_id]))

    alter table(:podcasts) do
      remove(:language_id)
    end
  end

  def down do
    alter table(:podcasts) do
      add(:language_id, :integer)
    end

    create(index(:podcasts, [:language_id]))
  end
end
