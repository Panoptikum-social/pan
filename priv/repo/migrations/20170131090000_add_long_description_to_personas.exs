defmodule Pan.Repo.Migrations.AddLongDescriptionToPersonas do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add(:long_description, :text)
    end
  end
end
