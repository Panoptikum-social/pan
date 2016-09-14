defmodule Pan.Repo.Migrations.CreateEnclosure do
  use Ecto.Migration

  def change do
    create table(:enclosures) do
      add :url, :string
      add :length, :string
      add :type, :string
      add :guid, :string
      add :episode_id, references(:episodes, on_delete: :nothing)

      timestamps
    end
    create index(:enclosures, [:episode_id])

  end
end
