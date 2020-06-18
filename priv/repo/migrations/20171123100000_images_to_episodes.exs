defmodule Pan.Repo.Migrations.AddImagesToEpisodes do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add(:image_title, :string)
      add(:image_url, :string)
    end
  end
end
