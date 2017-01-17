defmodule Pan.Repo.Migrations.AddPersonaIdToLikes do
  use Ecto.Migration

  def change do
    alter table(:likes) do
      add :persona_id, :integer
    end

    create index(:likes, [:persona_id])
  end
end
