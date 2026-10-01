defmodule Pan.Repo.Migrations.CreateCurations do
  use Ecto.Migration

  def change do
    create table(:curations) do
      # Curations outlive their author's account.
      add(:user_id, references(:users, on_delete: :nilify_all))
      add(:podcast_id, references(:podcasts, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:grade, :string, null: false)
      add(:text, :text)

      timestamps()
    end

    create(unique_index(:curations, [:user_id, :podcast_id, :community_id]))
    create(index(:curations, [:community_id, :podcast_id]))
  end
end
