defmodule Pan.Repo.Migrations.AddNamesakeToPodcasts do
  use Ecto.Migration

  # Set by an admin on the duplicates page for podcasts that share their
  # title but are different shows. The podcast page then points to the
  # namesakes, and the "same title" check stops listing them.
  def change do
    alter table(:podcasts) do
      add(:namesake, :boolean, default: false, null: false)
    end
  end
end
