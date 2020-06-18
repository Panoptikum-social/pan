defmodule Pan.Repo.Migrations.CreateContributorsPodcasts do
  use Ecto.Migration

  def change do
    create table(:contributors_podcasts, primary_key: false) do
      add(:contributor_id, references(:contributors))
      add(:podcast_id, references(:podcasts))
    end
  end
end
