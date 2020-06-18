defmodule Pan.Repo.Migrations.RemoveCommentAndRecommendToFromLike do
  use Ecto.Migration

  def change do
    create(index(:episodes, [:podcast_id, :id]))
    create(index(:episodes, [:podcast_id, :publishing_date, :inserted_at]))
  end
end
