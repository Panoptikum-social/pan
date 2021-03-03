defmodule Pan.Repo.Migrations.AddFediverseAddressToPersona do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add(:fediverse_address, :string)
    end
  end
end
