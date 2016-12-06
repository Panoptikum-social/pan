defmodule Pan.Repo.Migrations.RemoveCommentAndRecommendToFromLike do
  use Ecto.Migration

  def up do
    drop index(:likes, [:recommend_to_id])
    alter table(:likes) do
      remove :recommend_to_id
      remove :comment
    end
  end

  def down do
    alter table(:likes) do
      add :recommend_to_id, references(:users, on_delete: :nothing)
      add :comment, :string
    end
    create index(:likes, [:recommend_to_id])
  end
end
