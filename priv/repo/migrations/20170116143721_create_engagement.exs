defmodule Pan.Repo.Migrations.CreateEngagement do
  use Ecto.Migration

  def change do
    create table(:engagements) do
      add(:from, :date)
      add(:until, :date)
      add(:comment, :string)
      add(:role, :string)
      add(:persona_id, references(:personas, on_delete: :nothing))
      add(:podcast_id, references(:podcasts, on_delete: :nothing))

      timestamps()
    end

    create(index(:engagements, [:persona_id]))
    create(index(:engagements, [:podcast_id]))
  end
end
