defmodule Pan.Repo.Migrations.FixConstraintLikesEpisodes do
  use Ecto.Migration

  def change do
    alter table(:likes) do
      modify(:episode_id, references(:episodes, on_delete: :delete_all),
        from: references(:episodes, on_delete: :nothing))
    end
  end
end
