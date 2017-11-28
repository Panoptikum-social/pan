defmodule Pan.Repo.Migrations.MakeRssFeedPodcastIdIndexUnique do
  use Ecto.Migration

  def change do
    drop index(:rss_feeds, [:podcast_id])

    create unique_index(:rss_feeds, [:podcast_id])
  end
end
