defmodule Pan.Repo.Migrations.AddElasticBooleans do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add(:elastic, :boolean)
    end

    alter table(:users) do
      add(:elastic, :boolean)
    end

    alter table(:personas) do
      add(:elastic, :boolean)
    end

    alter table(:podcasts) do
      add(:elastic, :boolean)
    end

    alter table(:episodes) do
      add(:elastic, :boolean)
    end
  end
end
