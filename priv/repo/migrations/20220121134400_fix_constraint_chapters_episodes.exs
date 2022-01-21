defmodule Pan.Repo.Migrations.FixConstraintChaptersEpisodes do
  use Ecto.Migration

  def change do
    alter table(:chapters) do
      modify(:episode_id, references(:episodes, on_delete: :delete_all),
        from: references(:episodes, on_delete: :nothing))
    end
  end
end
