defmodule Pan.Repo.Migrations.CreateRecommendation do
  use Ecto.Migration

  def change do
    create table(:recommendations) do
      add(:comment, :string)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:podcast_id, references(:podcasts, on_delete: :nothing))
      add(:episode_id, references(:episodes, on_delete: :nothing))
      add(:chapter_id, references(:chapters, on_delete: :nothing))

      timestamps()
    end

    create(index(:recommendations, [:user_id]))
    create(index(:recommendations, [:podcast_id]))
    create(index(:recommendations, [:episode_id]))
    create(index(:recommendations, [:chapter_id]))
  end
end
