defmodule Pan.Repo.Migrations.AddCachesToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :episodes_count, :integer
      add :followers_count, :integer
      add :likes_count, :integer
      add :subscriptions_count, :integer
      add :latest_episode_publishing_date, :datetime
      add :publication_frequency, :float
    end
  end
end
