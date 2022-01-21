defmodule Pan.Repo.Migrations.FixConstraintRecommendationsChapters do
  use Ecto.Migration

  def change do
    alter table(:recommendations) do
      modify(:chapter_id, references(:chapters, on_delete: :delete_all),
        from: references(:chapters, on_delete: :nothing))
    end
  end
end
