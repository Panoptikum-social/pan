defmodule Pan.Repo.Migrations.RemoveAuthorFromPodcastsAndEpisodes do
  use Ecto.Migration

  def up do
    alter table(:podcasts) do
      remove(:author)
      remove(:owner_id)
    end

    alter table(:episodes) do
      remove(:author)
    end
  end

  def down do
    alter table(:podcasts) do
      add(:author, :string)
      add(:owner_id, references(:users, on_delete: :nothing))
    end

    create(index(:podcasts, [:owner_id]))

    alter table(:episodes) do
      add(:author, :string)
    end
  end
end
