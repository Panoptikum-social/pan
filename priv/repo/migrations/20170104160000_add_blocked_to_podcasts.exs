defmodule Pan.Repo.Migrations.AddBlockedToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :blocked, :boolean
    end
  end
end
