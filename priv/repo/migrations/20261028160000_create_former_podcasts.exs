defmodule Pan.Repo.Migrations.CreateFormerPodcasts do
  use Ecto.Migration

  # Deleted and merged podcasts under their old id, so the API can tell
  # clients what became of an id, see PanWeb.FormerPodcast. No foreign key
  # on new_id: a merge target can be deleted later on.
  def change do
    create table(:former_podcasts, primary_key: false) do
      add(:id, :integer, primary_key: true)
      add(:title, :string)
      add(:feed_url, :string)
      add(:new_id, :integer)
      add(:deleted_at, :naive_datetime)
    end

    create(index(:former_podcasts, [:new_id]))
  end
end
