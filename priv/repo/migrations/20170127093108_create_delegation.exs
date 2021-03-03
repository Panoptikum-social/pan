defmodule Pan.Repo.Migrations.CreateDelegation do
  use Ecto.Migration

  def change do
    create table(:delegations) do
      add(:persona_id, references(:personas, on_delete: :nothing))
      add(:delegate_id, references(:personas, on_delete: :nothing))

      timestamps()
    end

    create(index(:delegations, [:persona_id]))
    create(index(:delegations, [:delegate_id]))
    create(unique_index(:delegations, [:persona_id, :delegate_id]))
  end
end
