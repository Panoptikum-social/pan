defmodule Pan.Repo.Migrations.CreateCuratorships do
  use Ecto.Migration

  def change do
    create table(:curatorships, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
    end

    create(unique_index(:curatorships, [:user_id, :community_id]))
    create(index(:curatorships, [:community_id]))
  end
end
