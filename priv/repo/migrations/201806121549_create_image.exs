defmodule Pan.Repo.Migrations.CreateImage do
  use Ecto.Migration

  def change do
    create table(:images) do
      add(:filename, :string)
      add(:content_type, :string)
      add(:path, :string)
      add(:podcast_id, references(:podcasts, on_delete: :nothing))
      add(:episode_id, references(:episodes, on_delete: :nothing))
      add(:persona_id, references(:personas, on_delete: :nothing))

      timestamps()
    end

    create(index(:images, [:podcast_id]))
    create(index(:images, [:episode_id]))
    create(index(:images, [:persona_id]))
  end
end
