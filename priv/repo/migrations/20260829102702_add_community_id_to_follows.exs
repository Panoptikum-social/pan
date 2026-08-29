defmodule Pan.Repo.Migrations.AddCommunityIdToFollows do
  use Ecto.Migration

  def change do
    alter table(:follows) do
      add(:community_id, references(:communities, on_delete: :nothing))
    end

    create(index(:follows, [:community_id]))
  end
end
