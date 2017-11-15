defmodule Pan.Repo.Migrations.MorePodcastDateIndices do
  use Ecto.Migration

  def change do
    create index(:podcasts, ["subscriptions_count DESC NULLS LAST"])
    create index(:podcasts, ["likes_count DESC NULLS LAST"])
  end
end
