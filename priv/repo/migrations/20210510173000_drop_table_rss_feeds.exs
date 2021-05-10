defmodule Pan.Repo.Migrations.DropTableRssFeeds do
  use Ecto.Migration

  def change do
    drop table(:rss_feeds)
  end
end
