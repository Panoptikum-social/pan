defmodule Pan.Repo.Migrations.CreateFollowersPodcasts do
  use Ecto.Migration

  def change do
    create table(:followers_podcasts, primary_key: false) do
      add(:user_id, references(:users))
      add(:podcast_id, references(:podcasts))
    end
  end
end
