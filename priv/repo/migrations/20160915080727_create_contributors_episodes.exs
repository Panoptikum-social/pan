defmodule Pan.Repo.Migrations.CreateContributorsEpisodes do
  use Ecto.Migration

  def change do
    create table(:contributors_episodes, primary_key: false) do
      add(:contributor_id, references(:contributors))
      add(:episode_id, references(:episodes))
    end
  end
end
