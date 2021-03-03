defmodule Pan.Repo.Migrations.UniqueConstraintsForGigsAndEngagements do
  use Ecto.Migration

  def change do
    create(unique_index(:gigs, [:role, :persona_id, :episode_id]))
    create(unique_index(:engagements, [:role, :persona_id, :podcast_id]))
  end
end
