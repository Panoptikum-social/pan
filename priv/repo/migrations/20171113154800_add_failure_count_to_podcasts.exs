defmodule Pan.Repo.Migrations.AddFaiureCountToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add :failure_count, :integer
    end
  end
end
