defmodule Pan.Repo.Migrations.AddUpdatePausedToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add(:update_paused, :boolean)
    end
  end
end
