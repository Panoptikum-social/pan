defmodule Pan.Repo.Migrations.CreateRssFeed do
  use Ecto.Migration

  def change do
    create table(:rss_feeds) do
      add :content, :text
      add :podcast_id, references(:podcasts, on_delete: :nothing)

      timestamps()
    end
    create index(:rss_feeds, [:podcast_id])
  end
end
