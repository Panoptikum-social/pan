defmodule Pan.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add(:user_id, references(:users))
      add(:podcast_id, references(:podcasts))
    end
  end
end
