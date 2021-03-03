defmodule Pan.Repo.Migrations.AddManuallyUpdatedAtToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add(:manually_updated_at, :naive_datetime)
    end
  end
end
