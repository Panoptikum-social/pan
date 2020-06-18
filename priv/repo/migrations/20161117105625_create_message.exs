defmodule Pan.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:content, :string)
      add(:type, :string)
      add(:topic, :string)
      add(:subtopic, :string)
      add(:event, :string)
      add(:creator_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:messages, [:creator_id]))
    create(index(:messages, [:topic]))
    create(index(:messages, [:subtopic]))
    create(index(:messages, [:event]))
  end
end
