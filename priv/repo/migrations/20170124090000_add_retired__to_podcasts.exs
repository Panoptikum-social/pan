defmodule Pan.Repo.Migrations.AddUpdatePausedToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add(:retired, :boolean, default: false)
    end
  end
end
