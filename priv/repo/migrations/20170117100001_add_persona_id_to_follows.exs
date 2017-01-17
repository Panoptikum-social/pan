defmodule Pan.Repo.Migrations.AddPersonaIdToFollows do
  use Ecto.Migration

  def change do
    alter table(:follows) do
      add :persona_id, :integer
    end

    create index(:follows, [:persona_id])
  end
end
