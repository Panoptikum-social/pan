defmodule Pan.Repo.Migrations.CreateOPML do
  use Ecto.Migration

  def change do
    create table(:opmls) do
      add(:content_type, :string)
      add(:filename, :string)
      add(:path, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:opmls, [:user_id]))
  end
end
