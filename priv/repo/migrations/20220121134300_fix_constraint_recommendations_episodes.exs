defmodule Pan.Repo.Migrations.FixConstraintRecommendationsEpisodes do
  use Ecto.Migration

  def change do
    alter table(:recommendations) do
      modify(:episode_id, references(:episodes, on_delete: :delete_all),
        from: references(:episodes, on_delete: :nothing))
    end
  end
end
