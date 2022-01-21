defmodule Pan.Repo.Migrations.FixConstraintEnclosuresEpisodes do
  use Ecto.Migration

  def change do
    alter table(:enclosures) do
      modify(:episode_id, references(:episodes, on_delete: :delete_all),
        from: references(:episodes, on_delete: :nothing))
    end
  end
end
