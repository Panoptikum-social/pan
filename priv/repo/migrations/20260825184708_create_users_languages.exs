defmodule Pan.Repo.Migrations.CreateUsersLanguages do
  use Ecto.Migration

  def change do
    create table(:users_languages, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:language_id, references(:languages, on_delete: :delete_all), primary_key: true)
    end

    create(unique_index(:users_languages, [:user_id, :language_id]))
    create(index(:users_languages, [:language_id]))
  end
end
