defmodule Pan.Repo.Migrations.AddNextPodcastUpdateToPodcasts do
  use Ecto.Migration

  # Drives the new Pan.Job.RefreshPodcastMetadata monthly metadata-refresh
  # job (see backlog.md). Backfilled with a random datetime within the next
  # 30 days (rather than "now") so the initial rollout doesn't try to refresh
  # the whole catalog at once.
  def up do
    alter table(:podcasts) do
      add(:next_podcast_update, :naive_datetime)
    end

    create(index(:podcasts, [:next_podcast_update]))

    execute("""
    UPDATE podcasts
    SET next_podcast_update = NOW() + (random() * interval '30 days')
    """)
  end

  def down do
    alter table(:podcasts) do
      remove(:next_podcast_update)
    end
  end
end
