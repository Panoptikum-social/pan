defmodule Pan.Repo.Migrations.CreateChapter do
  use Ecto.Migration

  def change do
    create table(:chapters) do
      add :start, :string
      add :title, :string
      add :episode_id, references(:episodes, on_delete: :nothing)

      timestamps
    end
    create index(:chapters, [:episode_id])

  end
end
