defmodule Pan.Repo.Migrations.EpisodePublishingDateINDEX do
  use Ecto.Migration

  def change do
    create(index(:episodes, ["publishing_date ASC NULLS LAST", :podcast_id]))
  end
end
