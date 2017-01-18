defmodule Pan.Repo.Migrations.AddPersonaIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :persona_id, :integer
    end

    create index(:messages, [:persona_id])
  end
end
