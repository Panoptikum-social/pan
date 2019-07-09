defmodule Pan.Repo.Migrations.PodcastIdGuidIndexForEpisodes do
  use Ecto.Migration

  def change do
    create index(:episodes, [:podcast_id, :guid])
  end
end
