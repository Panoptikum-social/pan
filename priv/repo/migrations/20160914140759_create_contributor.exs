defmodule Pan.Repo.Migrations.CreateContributor do
  use Ecto.Migration

  def change do
    create table(:contributors) do
      add :name, :string
      add :uri, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:contributors, [:user_id])

  end
end
