defmodule Pan.Repo.Migrations.CreateContributer do
  use Ecto.Migration

  def change do
    create table(:contributers) do
      add :name, :string
      add :uri, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps
    end
    create index(:contributers, [:user_id])

  end
end
