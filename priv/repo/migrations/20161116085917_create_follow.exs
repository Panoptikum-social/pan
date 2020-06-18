defmodule Pan.Repo.Migrations.CreateFollow do
  use Ecto.Migration

  def change do
    create table(:follows) do
      add(:follower_id, references(:users, on_delete: :nothing))
      add(:podcast_id, references(:podcasts, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))
      add(:category_id, references(:categories, on_delete: :nothing))

      timestamps()
    end

    create(index(:follows, [:follower_id]))
    create(index(:follows, [:podcast_id]))
    create(index(:follows, [:user_id]))
    create(index(:follows, [:category_id]))

    drop(table(:followers_podcasts))
    drop(table(:followers_users))
  end
end
