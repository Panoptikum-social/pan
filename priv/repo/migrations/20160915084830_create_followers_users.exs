defmodule Pan.Repo.Migrations.CreateFollowersUsers do
  use Ecto.Migration

  def change do
    create table(:followers_users, primary_key: false) do
      add(:follower_id, references(:users))
      add(:user_id, references(:users))
    end
  end
end
