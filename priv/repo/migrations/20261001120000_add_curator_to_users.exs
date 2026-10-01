defmodule Pan.Repo.Migrations.AddCuratorToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:curator, :boolean, default: false)
    end
  end
end
