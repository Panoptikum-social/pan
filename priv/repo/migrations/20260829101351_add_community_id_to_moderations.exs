defmodule Pan.Repo.Migrations.AddCommunityIdToModerations do
  use Ecto.Migration

  def change do
    alter table(:moderations) do
      # category_id stays for now (kept alongside, not cut over) — see backlog.md
      add(:community_id, references(:communities, on_delete: :nothing))
    end

    create(index(:moderations, [:community_id]))
  end
end
