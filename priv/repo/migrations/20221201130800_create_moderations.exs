defmodule Pan.Repo.Migrations.CreateModerations do
  use Ecto.Migration

  def change do
    create table(:moderations, primary_key: false) do
      add(:user_id, references(:users))
      add(:category_id, references(:categories))
    end
  end
end
