defmodule Pan.Repo.Migrations.FixEpisodePublishingDateINDEX do
  use Ecto.Migration

  def change do
    drop(index(:episodes, ["publishing_date ASC NULLS LAST", :podcast_id]))
    create(index(:episodes, [:podcast_id, "publishing_date DESC NULLS LAST"]))
  end
end
