defmodule Pan.Repo.Migrations.CreateManifestation do
  use Ecto.Migration

  def change do
    create table(:manifestations) do
      add :persona_id, references(:personas, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:manifestations, [:persona_id])
    create index(:manifestations, [:user_id])

  end
end
