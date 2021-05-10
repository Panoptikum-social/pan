defmodule Pan.Repo.Migrations.RemoveThumbnailsFromEpisodes do
  use Ecto.Migration

  def change do
    alter table(:images) do
      remove :episode_id
    end

    alter table(:episodes) do
      remove :thumbnailed
    end
  end
end
