defmodule Pan.Repo.Migrations.CreateLike do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add(:comment, :string)
      add(:enjoyer_id, references(:users, on_delete: :nothing))
      add(:podcast_id, references(:podcasts, on_delete: :nothing))
      add(:episode_id, references(:episodes, on_delete: :nothing))
      add(:chapter_id, references(:chapters, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))
      add(:category_id, references(:categories, on_delete: :nothing))
      add(:recommend_to_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:likes, [:enjoyer_id]))
    create(index(:likes, [:podcast_id]))
    create(index(:likes, [:episode_id]))
    create(index(:likes, [:chapter_id]))
    create(index(:likes, [:user_id]))
    create(index(:likes, [:category_id]))
    create(index(:likes, [:recommend_to_id]))
  end
end
