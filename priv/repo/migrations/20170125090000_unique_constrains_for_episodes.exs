defmodule Pan.Repo.Migrations.UniqueConstraintsForEpisodes do
  use Ecto.Migration

  def change do
    create unique_index(:episodes, [:title, :podcast_id])
  end
end