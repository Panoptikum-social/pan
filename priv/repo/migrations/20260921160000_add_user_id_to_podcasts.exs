defmodule Pan.Repo.Migrations.AddUserIdToPodcasts do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add(:user_id, references(:users, on_delete: :nilify_all))
    end

    create(index(:podcasts, [:user_id]))
  end
end
