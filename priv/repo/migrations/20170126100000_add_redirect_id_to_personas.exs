defmodule Pan.Repo.Migrations.AddRedirectIdToPersonas do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :redirect_id, :integer
    end

    create index(:personas, [:redirect_id])
  end
end
