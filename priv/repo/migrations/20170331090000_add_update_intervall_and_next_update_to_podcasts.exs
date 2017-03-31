defmodule Pan.Repo.Migrations.AddUpdateIntervallAndNextUpdateToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :update_intervall, :integer
      add :next_update, :naive_datetime
    end
  end
end
