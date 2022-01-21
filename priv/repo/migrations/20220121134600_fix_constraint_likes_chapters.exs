defmodule Pan.Repo.Migrations.FixConstraintLikesChapters do
  use Ecto.Migration

  def change do
    alter table(:likes) do
      modify(:chapter_id, references(:chapters, on_delete: :delete_all),
        from: references(:chapters, on_delete: :nothing))
    end
  end
end
