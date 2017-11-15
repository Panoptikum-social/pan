defmodule Pan.Repo.Migrations.AddPersonaIdToLikes do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :user_id, :integer
    end

    create index(:personas, [:user_id])
  end
end
